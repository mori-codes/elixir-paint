defmodule FrameParser do
  def create() do
    %{content: <<>>, completed: false}
  end

  def parse_frame(parser, frame) do
    <<fin::1, _rsv1::1, _rsv2::1, _rsv3::1, _opcode::4, mask::1, initial_payload_len::7,
      rest::bitstring>> = frame

    {payload_len, rest} =
      case initial_payload_len do
        126 ->
          <<extra_len::16, rest::bitstring>> = rest
          {:binary.decode_unsigned(<<initial_payload_len, extra_len::16>>), rest}

        127 ->
          <<extra_len::64, rest::bitstring>> = rest
          {:binary.decode_unsigned(<<initial_payload_len, extra_len::64>>), rest}

        len ->
          {len, rest}
      end

    {mask, rest} =
      case mask do
        1 ->
          <<mask::32, rest::bitstring>> = rest
          {mask, rest}

        0 ->
          {0, rest}
      end

    payload =
      case mask do
        0 ->
          rest

        mask ->
          <<a::8, b::8, c::8, d::8>> = <<mask::32>>

          unmask(<<>>, rest, %{0 => a, 1 => b, 2 => c, 3 => d}, 0, payload_len * 8)
      end

    Map.put(parser, :completed, fin == 1)
    |> Map.update(:content, <<>>, fn content -> <<content::bitstring, payload::bitstring>> end)
  end

  defp unmask(acc, rest, mask, current_octet, total_len) do
    if current_octet * 8 >= total_len do
      acc
    else
      <<chunk::8, rest::bitstring>> = rest
      mask_octet = Map.get(mask, rem(current_octet, 4))

      <<acc::binary>> = <<acc::binary, Bitwise.bxor(chunk, mask_octet)>>
      unmask(acc, rest, mask, current_octet + 1, total_len)
    end
  end

  def encode_payload(payload) do
    raw_payload_len = byte_size(payload)

    payload_len =
      cond do
        raw_payload_len >= 8_323_071 -> <<127::7, raw_payload_len::64>>
        raw_payload_len >= 126 -> <<126::7, raw_payload_len::16>>
        raw_payload_len -> <<raw_payload_len::7>>
      end

    # This won't work if payload len is massive
    # Out of scope for now
    <<
      1::1,
      0::1,
      0::1,
      0::1,
      1::4,
      0::1,
      payload_len::bitstring,
      payload::bitstring
    >>
  end
end
