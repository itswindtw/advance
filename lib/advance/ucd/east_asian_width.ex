defmodule Advance.UCD.EastAsianWidth do
  defmacro __using__(_opts) do
    quote do
      ucd = Advance.UCD.EastAsianWidth.Parse.from_priv()
      {tree_1, tree_2} = Advance.UCD.EastAsianWidth.build_search_trees(ucd)

      @tree_1 tree_1
      @tree_2 tree_2

      def next(<<codepoint::utf8, rest::binary>> = string) do
        cond do
          Advance.UCD.EastAsianWidth.SearchTree.member?(@tree_2, codepoint) ->
            {2, rest}

          Advance.UCD.EastAsianWidth.SearchTree.member?(@tree_1, codepoint) ->
            {1, rest}

          true ->
            {nil, string}
        end
      end
    end
  end

  def build_search_trees(ucd) do
    map =
      Enum.group_by(
        ucd,
        fn
          {_k, :fullwidth} -> 2
          {_k, :wide} -> 2
          {_k, :halfwidth} -> 1
          {_k, :narrow} -> 1
        end,
        fn {k, _v} -> k end
      )

    {Advance.UCD.EastAsianWidth.SearchTree.new(Enum.sort(map[1])),
     Advance.UCD.EastAsianWidth.SearchTree.new(Enum.sort(map[2]))}
  end
end

defmodule Advance.UCD.EastAsianWidth.Parse do
  def from_priv do
    stream =
      Path.join(:code.priv_dir(:advance), "ucd/EastAsianWidth.txt")
      |> File.stream!()

    from_stream(stream)
  end

  def from_stream(stream) do
    stream
    |> Advance.UCD.Parse.trim()
    |> Stream.map(fn line ->
      [field_0, field_1] = String.split(line, ";", parts: 2)

      {parse_codepoints(field_0), parse_east_asian_width_property(field_1)}
    end)
    |> Stream.filter(fn {_codepoints, east_asian_width_property} ->
      MapSet.member?(
        MapSet.new([:fullwidth, :wide, :halfwidth, :narrow]),
        east_asian_width_property
      )
    end)
    |> Stream.flat_map(fn {codepoints, east_asian_width_property} ->
      Stream.map(codepoints, fn codepoint -> {codepoint, east_asian_width_property} end)
    end)
    |> Enum.into(%{})
  end

  def parse_codepoints(raw) do
    {raw_first, raw_last} =
      case String.split(raw, "..") do
        [raw] ->
          {raw, raw}

        [raw_first, raw_last] ->
          {raw_first, raw_last}
      end

    Range.new(String.to_integer(raw_first, 16), String.to_integer(raw_last, 16))
  end

  def parse_east_asian_width_property(raw) do
    [raw_property, _] = String.split(raw, " ", parts: 2)

    %{
      "A" => :ambiguous,
      "F" => :fullwidth,
      "H" => :halfwidth,
      "Na" => :narrow,
      "W" => :wide,
      "N" => :neutral
    }
    |> Map.fetch!(raw_property)
  end
end

defmodule Advance.UCD.EastAsianWidth.SearchTree do
  defstruct [:range, :left, :right]

  def new(list) do
    list
    |> merge_ranges()
    |> build_tree()
  end

  def member?(tree, x)

  def member?(nil, _), do: false

  def member?(tree, x) do
    cond do
      x >= tree.range.first && x <= tree.range.last ->
        true

      x < tree.range.first ->
        member?(tree.left, x)

      true ->
        member?(tree.right, x)
    end
  end

  defp merge_ranges(list) do
    list
    |> Stream.concat([nil])
    |> Stream.transform(
      nil,
      fn
        nil, range ->
          {[range], nil}

        x, nil ->
          {[], Range.new(x, x)}

        x, range when range.last + 1 == x ->
          {[], Range.new(range.first, x)}

        x, range ->
          {[range], Range.new(x, x)}
      end
    )
    |> Enum.to_list()
  end

  defp build_tree([]), do: nil

  defp build_tree([range]), do: %__MODULE__{range: range}

  defp build_tree(list) do
    {left_list, [range | right_list]} = Enum.split(list, div(length(list), 2))

    %__MODULE__{
      range: range,
      left: build_tree(left_list),
      right: build_tree(right_list)
    }
  end
end
