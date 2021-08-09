defmodule WCWidthTest do
  use ExUnit.Case

  test "report.csv" do
    exceptions =
      [
        # Cf: ARABIC
        Range.new(0x0600, 0x0605),
        0x061C,
        0x06DD,
        0x08E2,
        # Cf: SYRIAC
        0x070F,
        # Cf: MONGOLIAN
        0x180E,
        # Cf: INVISIBLE
        0x2064,
        Range.new(0x2066, 0x206F),
        # Cf: ZERO WIDTH NO-BREAK SPACE
        0xFEFF,
        # Cf: INTERLINEAR ANNOTATION
        Range.new(0xFFF9, 0xFFFB),
        # Cf: Kaithi
        0x110BD,
        0x110CD,
        # Cf: EGYPTIAN
        Range.new(0x13430, 0x13438),
        # Cf: SHORTHAND FORMAT
        Range.new(0x1BCA0, 0x1BCA3),
        # Cf: MUSICAL SYMBOL
        Range.new(0x1D173, 0x1D17A),
        # Emoji: REGIONAL INDICATOR SYMBOL LETTER
        Range.new(0x1F1E6, 0x1F1FF),
        # Cf: Tag
        0xE0001,
        Range.new(0xE0020, 0xE007F)
      ]
      |> Enum.reduce(MapSet.new(), fn
        %Range{} = range, acc ->
          Enum.into(range, acc)

        x, acc ->
          MapSet.put(acc, x)
      end)

    with {:ok, file} <- File.open(Path.join(__DIR__, "report.csv")) do
      errors =
        IO.stream(file, :line)
        |> Stream.map(fn line ->
          line = String.trim(line)

          [raw_codepoint, raw_width] = String.split(line, ",", parts: 2)

          codepoint = String.to_integer(raw_codepoint, 16)
          width = String.to_integer(raw_width)

          {raw_codepoint, codepoint, width}
        end)
        |> Stream.reject(fn {_, codepoint, _} ->
          MapSet.member?(exceptions, codepoint)
        end)
        |> Stream.reject(fn {_, codepoint, _} ->
          try do
            <<codepoint::utf8>>

            false
          rescue
            ArgumentError ->
              true
          end
        end)
        |> Stream.map(fn {raw_codepoint, codepoint, width} ->
          {raw_codepoint, width, Advance.of(<<codepoint::utf8>>)}
        end)
        |> Stream.reject(fn {_raw_codepoint, python_width, elixir_width} ->
          python_width == elixir_width || (python_width == -1 && elixir_width == 0)
        end)
        |> Enum.to_list()

      assert errors == []
    end
  end
end
