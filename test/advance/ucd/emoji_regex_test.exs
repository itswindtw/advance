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

    assert Regex.run(regex, "🇹🇼", capture: :all_but_first) == [
             <<0x1F1F9::utf8>>,
             <<0x1F1FC::utf8>>
           ]
  end

  test "EmojiRegex.emoji_regex" do
    ucd = EmojiRegex.Parse.from_priv()

    regex =
      EmojiRegex.emoji_sequence(ucd)
      |> Regex.compile!([:unicode, :extended])

    assert Regex.scan(regex, "🇹🇼🏴󠁧󠁢󠁳󠁣󠁴󠁿🏴‍☠️", capture: :first) ==
             [
               ["🇹🇼"],
               ["🏴󠁧󠁢󠁳󠁣󠁴󠁿"],
               ["🏴‍☠️"]
             ]

    assert Regex.scan(regex, "12⃣3️⃣4⃣️", capture: :first) ==
             [
               ["3️⃣"],
               ["4⃣️"]
             ]

    assert Regex.scan(regex, "👨👨‍🔬👩👩‍🔬", capture: :first) ==
             [
               ["👨"],
               ["👨‍🔬"],
               ["👩"],
               ["👩‍🔬"]
             ]
  end
end
