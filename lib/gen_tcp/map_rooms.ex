defmodule MapRooms do
  use GenServer

  def start() do
    GenServer.start(MapRooms, nil, name: MapRooms)
  end

  def stop() do
    GenServer.stop(MapRooms)
  end

  @impl GenServer
  def init(_init) do
    {:ok, %{}}
  end

  def join(channel, room) do
    IO.inspect("#{inspect(self())}: Joining map room")
    GenServer.cast(MapRooms, {:join, channel, room})
    channel
  end

  def update_map(room, position, color) do
    GenServer.cast(MapRooms, {:set, {position, color}, room})
  end

  def get_map(room) do
    GenServer.call(MapRooms, {:get, room})
  end

  @impl GenServer
  def handle_call({:get, room}, _from, state) do
    {:reply, Map.get(state, room) |> Map.get(:map), state}
  end

  @impl GenServer
  def handle_cast({:join, channel, room}, state) do
    {:noreply,
     Map.update(state, room, %{players: [channel], map: ColorMap.create()}, fn %{
                                                                                 players: players,
                                                                                 map: map
                                                                               } ->
       %{map: map, players: [channel | players]}
     end)}
  end

  @impl GenServer
  def handle_cast({:set, {position, color}, room}, state) do
    {:noreply,
     Map.update(state, room, %{players: [], map: ColorMap.create()}, fn %{
                                                                          players: players,
                                                                          map: map
                                                                        } ->
       color_map = ColorMap.update_color(map, position, color)

       for channel <- players do
         Channel.update(channel, color_map)
       end

       %{map: color_map, players: players}
     end)}
  end
end
