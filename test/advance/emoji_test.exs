defmodule Advance.EmojiTest do
  use ExUnit.Case

  test "emoji-test.txt" do
    stream =
      :code.priv_dir(:advance)
      |> Path.join("ucd/emoji/emoji-test.txt")
      |> File.stream!()

    result =
      stream
      |> Advance.UCD.Parse.trim()
      |> Stream.map(fn line ->
        [field_0, field_1] = String.split(line, ";", parts: 2)

        field_0 = String.trim(field_0)
        field_1 = Advance.UCD.Parse.trim(field_1)

        {string, _is_zwj_sequence} = parse_sequence(field_0)

        {string, parse_status(field_1)}
      end)
      |> Stream.filter(fn {_, status} ->
        status in [:fully_qualified, :component]
      end)
      |> Stream.reject(fn {string, _status} ->
        case Advance.Emoji.next(string) do
          {2, ""} ->
            true

          _ ->
            false
        end
      end)
      |> Enum.to_list()

    assert result == []
  end

  defp parse_sequence(raw) do
    parts = String.split(raw, " ")

    string =
      parts
      |> Enum.map(&String.to_integer(&1, 16))
      |> List.to_string()

    is_zwj_sequence = "\u200D" in parts

    {string, is_zwj_sequence}
  end

  defp parse_status(raw) do
    %{
      "component" => :component,
      "fully-qualified" => :fully_qualified,
      "minimally-qualified" => :minimally_qualified,
      "unqualified" => :unqualified
    }
    |> Map.fetch!(raw)
  end
end
