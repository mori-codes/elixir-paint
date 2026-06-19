defmodule Channel do
  use GenServer

  def start(client) do
    {:ok, channel} = GenServer.start(Channel, {client, nil})
    channel
  end

  def start_listen(channel) do
    GenServer.cast(channel, :listen)
  end

  def update(channel, color_map) do
    IO.inspect("#{inspect(channel)}: Should receive an update")
    IO.inspect(GenServer.cast(channel, {:new, color_map}))
  end

  def send_response(channel, data) do
    GenServer.cast(channel, {:response, data})
  end

  @impl GenServer
  def init({client, _listener}) do
    IO.inspect("#{inspect(self())}: Creating GenServer")
    MapRooms.join(self(), "room_1")

    {:ok, {client, ChannelListener.start(self(), client)}}
  end

  @impl GenServer
  def handle_cast(:listen, {client, listener}) do
    ChannelListener.start_listen(listener)
    {:noreply, {client, listener}}
  end

  @impl GenServer
  def handle_cast({:new, color_map}, {client, listener}) do
    IO.inspect("#{inspect(self())}: Received update")

    send_response(self(), color_map)
    {:noreply, {client, listener}}
  end

  def handle_cast({:response, data}, {client, listener}) do
    ready_data = Jason.encode!(data) |> FrameParser.encode_payload()

    IO.inspect(
      "#{inspect(self())}: Creating response"
    )

    :gen_tcp.send(client, ready_data)
    {:noreply, {client, listener}}
  end
end
