defmodule HTTPParser do
  def create() do
    %{request: nil, headers: %{}, headers_done: false, body: "", rest: nil, complete: false}
  end

  def parse_string(parser, string) do
    chunks = String.split(string, "\r\n")
    parse(parser, chunks)
  end

  defp parse(parser, []) do
    Map.put(
      parser,
      :complete,
      parser.body == "" or
        Integer.to_string(byte_size(Map.get(parser, :body))) ==
          Map.get(parser, :headers) |> Map.get("Content-Length")
    )
  end

  defp parse(%{request: nil} = parser, chunks) do
    [first | rest] = chunks

    complete_first =
      case parser.rest do
        nil -> first
        prev -> prev <> first
      end

    parser =
      if(String.match?(complete_first, ~r/^\w+ [\/\w]+ HTTP\/1.1$/)) do
        Map.put(parser, :request, complete_first) |> Map.put(:rest, nil)
      else
        Map.put(parser, :rest, complete_first)
      end

    parse(parser, rest)
  end

  defp parse(%{headers_done: false} = parser, chunks) do
    [header | rest] = chunks

    cond do
      header == "" ->
        Map.put(parser, :headers_done, true) |> parse(rest)

      String.match?(header, ~r/\w+: \w+/) ->
        parser |> add_header(header) |> parse(rest)

      true ->
        # This is an issue, if a header is malformed
        Map.put(parser, :rest, header) |> parse(rest)
    end
  end

  defp parse(parser, chunks) do
    parser |> Map.put(:body, parser.body <> Enum.join(chunks, "\r\n")) |> parse([])
  end

  defp add_header(parser, header) do
    [key | value_array] = String.split(header, ": ")
    Map.put(parser, :headers, Map.put(parser.headers, key, hd(value_array)))
  end
end
