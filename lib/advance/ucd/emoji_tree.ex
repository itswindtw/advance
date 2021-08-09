defmodule Advance.UCD.EmojiTree do
  defmacro __using__(_opts) do
    quote do
      @ucd Advance.UCD.EmojiTree.Parse.from_priv()
           |> Advance.UCD.EmojiTree.put_apple_keycap_sequences()

      def next(string) do
        case Advance.UCD.EmojiTree.next(@ucd, string) do
          :error -> {nil, string}
          {:ok, rest} -> {2, rest}
        end
      end
    end
  end

  def next(tree, string) do
    with {<<codepoint::utf8>>, string} <- String.next_codepoint(string),
         {:ok, tree} <- Map.fetch(tree.children, codepoint),
         {:ok, string} <- next(tree, string) do
      {:ok, string}
    else
      _ ->
        if tree.complete?,
          do: {:ok, string},
          else: :error
    end
  end

  def put_apple_keycap_sequences(tree) do
    [
      0x0023,
      0x002A,
      0x0030,
      0x0031,
      0x0032,
      0x0033,
      0x0034,
      0x0035,
      0x0036,
      0x0037,
      0x0038,
      0x0039
    ]
    |> Enum.reduce(tree, fn x, tree ->
      Advance.UCD.EmojiTree.Tree.put(tree, [x, 0x20E3, 0xFE0F])
    end)
  end
end

defmodule Advance.UCD.EmojiTree.Tree do
  defstruct [:complete?, children: %{}]

  def put(tree, [codepoint]) do
    update_in(tree.children, fn children ->
      Map.update(children, codepoint, %Advance.UCD.EmojiTree.Tree{complete?: true}, fn node ->
        %{node | complete?: true}
      end)
    end)
  end

  def put(tree, [codepoint | codepoints]) do
    update_in(tree.children, fn children ->
      Map.update(
        children,
        codepoint,
        put(%Advance.UCD.EmojiTree.Tree{complete?: false}, codepoints),
        fn node ->
          put(node, codepoints)
        end
      )
    end)
  end
end

defmodule Advance.UCD.EmojiTree.Parse do
  def from_priv do
    emoji_sequences_stream =
      Path.join(:code.priv_dir(:advance), "ucd/emoji/emoji-sequences.txt")
      |> File.stream!()

    emoji_zwj_sequences_stream =
      Path.join(:code.priv_dir(:advance), "ucd/emoji/emoji-zwj-sequences.txt")
      |> File.stream!()

    from_stream(Stream.concat(emoji_sequences_stream, emoji_zwj_sequences_stream))
  end

  def from_stream(stream) do
    stream
    |> Advance.UCD.Parse.trim()
    |> Stream.map(fn line ->
      [field_0, _] = String.split(line, ";", parts: 2)

      field_0 = String.trim(field_0)

      parse_codepoint_sequence(field_0)
    end)
    |> Stream.flat_map(fn
      {:sequence, parts} ->
        [parts]

      {:range, range} ->
        Stream.map(range, fn codepoint -> [codepoint] end)

      {:one, codepoint} ->
        [[codepoint]]
    end)
    |> Enum.reduce(
      %Advance.UCD.EmojiTree.Tree{complete?: false},
      &Advance.UCD.EmojiTree.Tree.put(&2, &1)
    )
  end

  def parse_codepoint_sequence(raw) do
    cond do
      String.contains?(raw, " ") ->
        parts =
          String.split(raw, " ")
          |> Enum.map(&String.to_integer(&1, 16))

        {:sequence, parts}

      String.contains?(raw, "..") ->
        [raw_first, raw_last] = String.split(raw, "..")

        {:range, Range.new(String.to_integer(raw_first, 16), String.to_integer(raw_last, 16))}

      true ->
        {:one, String.to_integer(raw, 16)}
    end
  end
end
