defmodule Advance.UCD.EastAsianWidthTest do
  use ExUnit.Case

  alias Advance.UCD.EastAsianWidth

  test "EastAsianWidth.Parse.from_priv" do
    data = EastAsianWidth.Parse.from_priv()

    # space
    assert data[0x0020] == :narrow

    # 你好
    assert data[0x20320] == :wide
    assert data[0x22909] == :wide

    # zero width space
    assert data[0x200B] == nil

    # ambiguous
    assert data[0x2010] == nil
    assert data[0x324F] == nil

    # neutral
    assert data[0x24EA] == nil
  end

  test "EastAsianWidth.SearchTree.new" do
    assert search_tree() == %EastAsianWidth.SearchTree{
             range: Range.new(6, 6),
             left: %EastAsianWidth.SearchTree{
               range: Range.new(1, 3)
             },
             right: %EastAsianWidth.SearchTree{
               range: Range.new(8, 9)
             }
           }
  end

  test "EastAsianWidth.SearchTree.member?" do
    tree = search_tree()

    assert EastAsianWidth.SearchTree.member?(tree, 6) == true
    assert EastAsianWidth.SearchTree.member?(tree, 3) == true
    assert EastAsianWidth.SearchTree.member?(tree, 4) == false
  end

  defp search_tree do
    [1, 2, 3, 6, 8, 9]
    |> EastAsianWidth.SearchTree.new()
  end
end
