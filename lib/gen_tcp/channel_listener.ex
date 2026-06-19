defmodule ChannelListener do
  use GenServer

  def start(channel, tcp_client) do
    {:ok, listener} = GenServer.start(ChannelListener, {channel, tcp_client})
    listener
  end

  def start_listen(channel) do
    GenServer.cast(channel, :listen)
  end

  defp listen(parser, {channel, tcp_client}) do
    color_map = MapRooms.get_map("room_1")

    IO.inspect("#{inspect(self())}: Waiting for receive")

    case :gen_tcp.recv(tcp_client, 0) do
      {:ok, data} ->
        IO.inspect("#{inspect(self())}: Received #{data}")

        parser = FrameParser.parse_frame(parser, data)

        parser =
          case parser.completed do
            true -> parser
            false -> listen(parser, {channel, tcp_client})
          end

        case decode_message(parser) do
          :fail ->
            listen(FrameParser.create(), {channel, tcp_client})

          :get_colors ->
            Channel.send_response(channel, color_map)

          {:set_color, color, position} ->
            MapRooms.update_map("room_1", position, color)
        end

      {:error, :closed} ->
        # TODO: Create GenServer stop
        :close
    end

    start_listen(self())
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
  def init({channel, tcp_client}) do
    {:ok, {channel, tcp_client}}
  end

  @impl GenServer
  def handle_cast(:listen, {channel, tcp_client}) do
    listen(FrameParser.create(), {channel, tcp_client})
    {:noreply, {channel, tcp_client}}
  end
end
