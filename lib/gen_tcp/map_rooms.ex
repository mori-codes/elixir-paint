defmodule MapRooms do
  use GenServer

  def start() do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  @impl GenServer
  def init(_init) do
    {:ok, %{}}
  end

  def join(channel, room) do
    IO.inspect("#{inspect(self())}: Joining map room")
    GenServer.cast(__MODULE__, {:join, channel, room})
    channel
  end

  def exit(channel, room) do
    IO.inspect("Player exiting room")
    GenServer.cast(__MODULE__, {:exit, channel, room})
  end

  def update_map(room, position, color) do
    GenServer.cast(__MODULE__, {:set, {position, color}, room})
  end

  def get_map(room) do
    GenServer.call(__MODULE__, {:get, room})
  end

  def get_rooms() do
    GenServer.call(__MODULE__, :list)
  end

  @impl GenServer
  def handle_call({:get, room}, _from, state) do
    {:reply, Map.get(state, room) |> Map.get(:map), state}
  end

  @impl GenServer
  def handle_call(:list, _from, state) do
    {:reply,
     Map.to_list(state)
     |> Enum.reduce(%{}, fn {key, value}, acc ->
       Map.put(acc, key, %{
         map: Map.get(value, :map),
         players: Map.get(value, :players) |> Enum.count()
       })
     end), state}
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
  def handle_cast({:exit, channel, room}, state) do
    {:noreply,
     Map.update(state, room, %{players: [channel], map: ColorMap.create()}, fn %{
                                                                                 players: players,
                                                                                 map: map
                                                                               } ->
       %{map: map, players: Enum.filter(players, fn player -> player !== channel end)}
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
