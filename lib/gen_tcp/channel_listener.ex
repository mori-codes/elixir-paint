defmodule ChannelListener do
  use GenServer

  def start(channel, tcp_client, room_name) do
    {:ok, listener} = GenServer.start(ChannelListener, {channel, tcp_client, room_name})
    listener
  end

  def start_listen(channel) do
    GenServer.cast(channel, :listen)
  end

  defp listen(parser, {channel, tcp_client, room_name}) do
    color_map = MapRooms.get_map(room_name)

    IO.inspect("#{inspect(self())}: Waiting for receive")

    case :gen_tcp.recv(tcp_client, 0) do
      {:ok, data} ->
        IO.inspect("#{inspect(self())}: Received #{data}")

        parser = FrameParser.parse_frame(parser, data)

        parser =
          case parser.completed do
            true -> parser
            false -> listen(parser, {channel, tcp_client, room_name})
          end

        case decode_message(parser) do
          :fail ->
            listen(FrameParser.create(), {channel, tcp_client, room_name})

          :get_colors ->
            Channel.send_response(channel, color_map)

          {:set_color, color, position} ->
            MapRooms.update_map(room_name, position, color)
        end

        start_listen(self())

      {:error, :closed} ->
        :gen_tcp.close(tcp_client)
        :close
    end
  end

  defp decode_message(parser) do
    data = Jason.decode!(parser.content)
    IO.inspect("#{inspect(self())}: Decoded data #{inspect(data)}")

    case data do
      %{"type" => "get"} ->
        :get_colors

      %{"type" => "set_colors", "change_color" => [color, position]} ->
        {:set_color, color, position}

      _any ->
        :fail
    end
  end

  @impl GenServer
  def init({channel, tcp_client, room_name}) do
    {:ok, {channel, tcp_client, room_name}}
  end

  @impl GenServer
  def handle_cast(:listen, {channel, tcp_client, room_name}) do
    listen(FrameParser.create(), {channel, tcp_client, room_name})
    {:noreply, {channel, tcp_client, room_name}}
  end
end
