defmodule App do
  def start() do
    IO.puts("Hola")
  end
end

defmodule Tree do
  def create(root) do
    {root, {nil, nil}}
  end

  def get_root(tree) do
    {root, _} = tree
    root
  end

  def add_value({root, {left, right}}, value) do
    if value > root do
      if right == nil do
        {root, {left, create(value)}}
      else
        {root, {left, add_value(right, value)}}
      end
    else
      if left == nil do
        {root, {create(value), right}}
      else
        {root, {add_value(left, value), right}}
      end
    end
  end

  def print_in_order(nil) do
    :ok
  end

  def print_in_order({root, {left, right}}) do
    print_in_order(left)
    IO.puts(root)
    print_in_order(right)
    {root, {left, right}}
  end

  defp add_to_level(nil, _, offset, level_map) do
    {level_map, offset, offset}
  end

  defp add_to_level({root, {nil, nil}}, level, offset, level_map) do
    current_level_list = Map.get(level_map, level, [])

    updated_level_map =
      Map.put(level_map, level, [{root, offset, {0, 0}} | current_level_list])

    new_offset = floor(:math.log10(root)) + 1 + offset

    {updated_level_map, new_offset, offset}
  end

  defp add_to_level({root, {left, right}}, level, offset, level_map) do
    current_level_list = Map.get(level_map, level, [])

    {updated_level_map, current_offset, left_child_offset} =
      add_to_level(left, level + 1, offset, level_map)

    new_offset = floor(:math.log10(root)) + 1 + current_offset

    {updated_level_map, final_offset, right_child_offset} =
      add_to_level(right, level + 1, new_offset, updated_level_map)

    distance_to_left = if left !== nil do current_offset - left_child_offset else 0 end
    distance_to_right = if right !== nil do right_child_offset - current_offset else 0 end
    updated_level_map =
      Map.put(updated_level_map, level, [
        {root, current_offset,
         {distance_to_left, distance_to_right}}
        | current_level_list
      ])

    {updated_level_map, final_offset, current_offset}
  end

  def print_by_level(tree) do
    spacing = 1
    {level_map, _max_offset, _child_offset} = add_to_level(tree, 0, 0, %{})

    Enum.sort(Map.keys(level_map))
    |> Enum.each(fn key ->
      items = Enum.reverse(Map.get(level_map, key, []))

      {values, arrows} =
        Enum.reduce(items, {"", ""}, fn {value, offset, {left, right}}, {values, arrows} ->
          index = offset * spacing
          distance_from_last_value = index - String.length(values)

          new_values =
            values <> String.duplicate(" ", distance_from_last_value) <> to_string(value)

          width = floor(:math.log10(value)) + 1
          distance_from_last_arrow = index - left - String.length(arrows)
          spaces = String.duplicate(" ", max(distance_from_last_arrow, 0))

          lines =
            "#{if left > 0 do
              String.duplicate("_", left - 1) <> "/"
            else
              String.duplicate(" ", left)
            end}" <>
              String.duplicate(" ", width) <>
              "#{if right > 0 do
                "\\" <> String.duplicate("_", right - 1)
              else
                String.duplicate(" ", right)
              end}"

          new_arrows = arrows <> spaces <> lines

          {new_values, new_arrows}
        end)

      IO.puts(values)
      IO.puts(arrows)
    end)
  end

  def rotate_l_r({root, {{left_root, {left_left_child, {left_right_root, {nil, nil}}}}, right}})
      when left_root != nil and left_right_root != nil do
    {
      left_right_root,
      {
        {
          left_root,
          {left_left_child, nil}
        },
        {
          root,
          {
            nil,
            right
          }
        }
      }
    }
  end

  def rotate_l_r(_tree) do
    :unsupported_operation
  end
end

defmodule RandomLoop do
  def random_loop(0, value, fun) do
    fun.(:rand.uniform(1000), value)
  end

  def random_loop(iter, value, fun) do
    ret = fun.(:rand.uniform(1000), value)
    random_loop(iter - 1, ret, fun)
  end
end

# tree =
#   Tree.create(3)
#   |> Tree.add_value(5)
#   |> Tree.add_value(1)
#   |> Tree.add_value(4)
#   |> Tree.add_value(2)

# IO.puts("ORIGINAL TREE:")
# Tree.print_by_level(tree)

# tree = Tree.rotate_l_r(tree)
# IO.puts("TREE AFTER ROTATION:")
# Tree.print_by_level(tree)

IO.puts("MEGA TREE:")

tree2 =
  RandomLoop.random_loop(100, Tree.create(:rand.uniform(1000)), fn value, itree ->
    Tree.add_value(itree, value)
  end)

Tree.print_by_level(tree2)
