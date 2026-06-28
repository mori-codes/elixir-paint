defmodule Server do
  def accept(port) do
    MapRooms.start()

    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])

    spawn(fn -> loop_acceptor(socket) end)
    socket
  end

  def close_server(server) do
    :gen_tcp.close(server)
    MapRooms.stop()
  end

  def loop_acceptor(socket) do
    IO.inspect("loop_accepting")
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  def serve(socket) do
    IO.inspect(:inet.peername(socket))
    parser = HTTPParser.create()
    mode = socket |> read_line(parser) |> write_line(socket)

    case mode do
      :close -> :gen_tcp.close(socket)
      {:keep, room_name} -> serve_web_socket(socket, room_name)
    end
  end

  def read_line(socket, parser) do
    IO.puts("reading reading")
    request =
      case :gen_tcp.recv(socket, 0, 100) do
        {:ok, data} ->
          parser = HTTPParser.parse_string(parser, data)
          IO.inspect({data, parser})

          case parser.complete do
            true -> parser
            false -> read_line(socket, parser)
          end

        {:error, :closed} ->
          parser
        {:error, :timeout} ->
          parser
      end

    request
  end

  def write_line(request, socket) do
    IO.inspect(request.request)
    params = get_path_params(request.request)
    IO.inspect(params)

    case request.headers["Connection"] do
      "Upgrade" ->
        sec_websocket_accept =
          request.headers["Sec-WebSocket-Key"] <> "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

        sec_websocket_accept = :crypto.hash(:sha, sec_websocket_accept) |> Base.encode64()

        :gen_tcp.send(socket, """
        HTTP/1.1 101 Switching Protocols\r
        Connection: Upgrade\r
        Upgrade: websocket\r
        Sec-WebSocket-Accept: #{sec_websocket_accept}\r
        \r
        """)

        {:keep, params}

      _any ->
        IO.inspect(MapRooms.get_rooms())
        body = Jason.encode!(MapRooms.get_rooms())

        :gen_tcp.send(socket, """
        HTTP/1.1 200 OK\r
        Content-Type: application/json\r
        Content-Length: #{byte_size(body)}\r
        Access-Control-Allow-Origin: *\r
        \r
        #{body}

        """)

        :close
    end
  end

  def serve_web_socket(socket, room_name) do
    IO.inspect("creating web socket")
    Channel.start(socket, room_name) |> Channel.start_listen()
    # frame_parser = FrameParser.create()
    # message = socket |> read_web_socket_binary(frame_parser)

    # case message do
    #   :close ->
    #     :gen_tcp.close(socket)

    #   {:ok, content} ->
    #     IO.inspect(content)
    #     serve_web_socket(socket)

    #   _any ->
    #     serve_web_socket(socket)
    # end
  end

  # def read_web_socket_binary(socket, parser) do
  #   case :gen_tcp.recv(socket, 0) do
  #     {:ok, data} ->
  #       parser = FrameParser.parse_frame(parser, data)

  #       parser =
  #         case parser.completed do
  #           true -> parser
  #           false -> read_web_socket_binary(socket, parser)
  #         end

  #       {:ok, parser.content}

  #     {:error, :closed} ->
  #       :close
  #   end
  # end

  defp get_path_params(params) do
    case params do
      nil -> nil
      request -> String.split(request, " ") |> Enum.at(1) |> String.split("/") |> Enum.at(-1)
    end
  end
end
