defmodule Advance.UCD.EmojiRegexTest do
  use ExUnit.Case

  alias Advance.UCD.EmojiRegex

  test "EmojiRegex.Parse.from_priv" do
    data = EmojiRegex.Parse.from_priv()

    assert length(data[:emoji]) > 0
  end

  test "EmojiRegex.regional_indicator" do
    flag_sequence =
      Enum.join([
        "(" <> EmojiRegex.regional_indicator() <> ")",
        "(" <> EmojiRegex.regional_indicator() <> ")"
      ])

    regex = Regex.compile!(flag_sequence, "u")

    assert Regex.run(regex, "πΉπΌ", capture: :all_but_first) == [
             <<0x1F1F9::utf8>>,
             <<0x1F1FC::utf8>>
           ]
  end

  test "EmojiRegex.emoji_regex" do
    ucd = EmojiRegex.Parse.from_priv()

    regex =
      EmojiRegex.emoji_sequence(ucd)
      |> Regex.compile!([:unicode, :extended])

    assert Regex.scan(regex, "πΉπΌπ΄σ §σ ’σ ³σ £σ ΄σ Ώπ΄ββ οΈ", capture: :first) ==
             [
               ["πΉπΌ"],
               ["π΄σ §σ ’σ ³σ £σ ΄σ Ώ"],
               ["π΄ββ οΈ"]
             ]

    assert Regex.scan(regex, "12β£3οΈβ£4β£οΈ", capture: :first) ==
             [
               ["3οΈβ£"],
               ["4β£οΈ"]
             ]

    assert Regex.scan(regex, "π¨π¨βπ¬π©π©βπ¬", capture: :first) ==
             [
               ["π¨"],
               ["π¨βπ¬"],
               ["π©"],
               ["π©βπ¬"]
             ]
  end
end
