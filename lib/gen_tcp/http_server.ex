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
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  def serve(socket) do
    parser = HTTPParser.create()
    mode = socket |> read_line(parser) |> write_line(socket)

    case mode do
      :close -> :gen_tcp.close(socket)
      :keep -> serve_web_socket(socket)
    end
  end

  def read_line(socket, parser) do
    request =
      case :gen_tcp.recv(socket, 0) do
        {:ok, data} ->
          parser = HTTPParser.parse_string(parser, data)

          case parser.complete do
            true -> parser
            false -> read_line(socket, parser)
          end

        {:error, :closed} ->
          parser
      end

    request
  end

  def write_line(request, socket) do
    body = Jason.encode!("Hello world!")

    case request.headers["Connection"] do
      nil ->
        :gen_tcp.send(socket, """
        HTTP/1.1 200 OK\r
        Content-Type: application/json\r
        Content-Length: #{byte_size(body)}\r
        Access-Control-Allow-Origin: *\r
        \r
        #{body}

        """)

        :close

      "Upgrade" ->
        IO.puts("upgrading")

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

        :keep
    end
  end

  def serve_web_socket(socket) do
    Channel.start(socket) |> Channel.start_listen()
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
end
