defmodule Advance.UCD.EmojiTreeTest do
  use ExUnit.Case

  alias Advance.UCD.EmojiTree

  def tree do
    %EmojiTree.Tree{complete?: false}
    |> EmojiTree.Tree.put([0x2721, 0xFE0F])
    |> EmojiTree.Tree.put([0x1F939])
    |> EmojiTree.Tree.put([0x1F939, 0x1F3FB])
    |> EmojiTree.Tree.put([0x1F939, 0x1F3FC])
  end

  test "EmojiTree.Tree" do
    assert tree() == %EmojiTree.Tree{
             complete?: false,
             children: %{
               0x2721 => %EmojiTree.Tree{
                 complete?: false,
                 children: %{
                   0xFE0F => %EmojiTree.Tree{
                     complete?: true,
                     children: %{}
                   }
                 }
               },
               0x1F939 => %EmojiTree.Tree{
                 complete?: true,
                 children: %{
                   0x1F3FB => %EmojiTree.Tree{
                     complete?: true,
                     children: %{}
                   },
                   0x1F3FC => %EmojiTree.Tree{
                     complete?: true,
                     children: %{}
                   }
                 }
               }
             }
           }
  end

  test "EmojiTree.next" do
    assert EmojiTree.next(tree(), List.to_string([0x2721, 0xFE0F])) ==
             {:ok, ""}

    assert EmojiTree.next(tree(), List.to_string([0x2721])) == :error

    assert EmojiTree.next(tree(), List.to_string([0x1F939, 0x1F3FB, 0x2721])) ==
             {:ok, <<0x2721::utf8>>}

    assert EmojiTree.next(tree(), List.to_string([0x1F939])) ==
             {:ok, ""}

    assert EmojiTree.next(tree(), List.to_string([0x1F939, 0x1F3FB])) ==
             {:ok, ""}
  end
end
