defmodule Advance do
  @moduledoc """
  Documentation for `Advance`.
  """

  @doc """
  Calculate the width of a string

  ## Examples

      iex> Advance.of("你好👋")
      6
      iex> Advance.of("🔬👩‍🔬")
      4

  """
  def of(string), do: do_of(string, 0)

  defp do_of(<<>>, acc), do: acc

  defp do_of(string, acc) do
    {width, string} = next(string)

    do_of(string, acc + width)
  end

  def next(string) do
    mods = [
      Advance.Emoji,
      Advance.UnicodeData,
      Advance.EastAsianWidth,
      Advance.Hardcoded
    ]

    Stream.map(mods, fn mod -> apply(mod, :next, [string]) end)
    |> Enum.find(fn {width, _string} -> width != nil end)
  end
end
