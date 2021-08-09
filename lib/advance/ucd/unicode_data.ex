defmodule Advance.UCD.UnicodeData do
  defmacro __using__(_opts) do
    quote do
      @dialyzer {:no_opaque, next: 1}
      @ucd Advance.UCD.UnicodeData.Parse.from_priv()

      def next(<<0x00AD::utf8, rest::binary>>), do: {1, rest}

      def next(<<codepoint::utf8, rest::binary>> = string) do
        if MapSet.member?(@ucd, codepoint) do
          {0, rest}
        else
          {nil, string}
        end
      end
    end
  end
end

defmodule Advance.UCD.UnicodeData.Parse do
  def from_priv do
    stream =
      Path.join(:code.priv_dir(:advance), "ucd/UnicodeData.txt")
      |> File.stream!()

    from_stream(stream)
  end

  def from_stream(stream) do
    stream
    |> Advance.UCD.Parse.trim()
    |> Stream.map(fn line ->
      [raw_codepoint, name, general_category | _] = String.split(line, ";")

      {String.to_integer(raw_codepoint, 16), name, general_category}
    end)
    |> Stream.transform(nil, fn parts, acc ->
      {codepoint, name, general_category} = parts

      cond do
        acc ->
          {[{Range.new(elem(acc, 0), codepoint), general_category}], nil}

        String.ends_with?(name, ", First>") ->
          {[], parts}

        true ->
          {[{Range.new(codepoint, codepoint), general_category}], nil}
      end
    end)
    |> Stream.map(fn {codepoints, general_category} ->
      {codepoints, parse_general_category(general_category)}
    end)
    |> Stream.filter(fn {_codepoints, general_category} ->
      MapSet.member?(
        MapSet.new([
          :nonspacing_mark,
          :enclosing_mark,
          :line_separator,
          :paragraph_separator,
          :control,
          :format,
          :surrogate
        ]),
        general_category
      )
    end)
    |> Stream.flat_map(fn {codepoints, _general_category} ->
      Stream.map(codepoints, fn codepoint -> codepoint end)
    end)
    |> Stream.filter(fn codepoint -> valid_codepoint?(codepoint) end)
    |> Enum.into(MapSet.new())
  end

  def parse_general_category(raw) do
    %{
      "Lu" => :uppercase_letter,
      "Ll" => :lowercase_letter,
      "Lt" => :titlecase_letter,
      "Lm" => :modifier_letter,
      "Lo" => :other_letter,
      "Mn" => :nonspacing_mark,
      "Mc" => :spacing_mark,
      "Me" => :enclosing_mark,
      "Nd" => :decimal_number,
      "Nl" => :letter_number,
      "No" => :other_number,
      "Pc" => :connector_punctuation,
      "Pd" => :dash_punctuation,
      "Ps" => :open_punctuation,
      "Pe" => :close_punctuation,
      "Pi" => :initial_punctuation,
      "Pf" => :final_punctuation,
      "Po" => :other_punctuation,
      "Sm" => :math_symbol,
      "Sc" => :currency_symbol,
      "Sk" => :modifier_symbol,
      "So" => :other_symbol,
      "Zs" => :space_separator,
      "Zl" => :line_separator,
      "Zp" => :paragraph_separator,
      "Cc" => :control,
      "Cf" => :format,
      "Cs" => :surrogate,
      "Co" => :private_use,
      "Cn" => :unassigned
    }
    |> Map.fetch!(raw)
  end

  def valid_codepoint?(codepoint) do
    try do
      <<codepoint::utf8>>

      true
    rescue
      ArgumentError -> false
    end
  end
end
