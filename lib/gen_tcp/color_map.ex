defmodule ColorMap do
  def create() do
    Enum.map(0..63, fn _value -> "#ffffff" end)
  end

  @spec update_color(list(), integer(), any()) :: list()
  def update_color(color_map, position, color) do
    List.replace_at(color_map, position, color)
  end
end
