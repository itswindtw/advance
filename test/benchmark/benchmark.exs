defmodule Benchmark do
  def run do
    # Range.new(0x0, 0xFFFF)
    codepoints =
      Range.new(0x0, 0x10FFFF)
      |> Stream.filter(&Advance.UCD.UnicodeData.Parse.valid_codepoint?/1)

    {time, _} =
      :timer.tc(fn ->
        Enum.each(codepoints, fn codepoint -> Advance.of(<<codepoint::utf8>>) end)
      end)

    IO.inspect(time / 1_000_000)
    IO.inspect(:erlang.memory())
  end
end

Benchmark.run()
