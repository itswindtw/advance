defmodule Advance.UCD.EmojiRegex do
  defmacro __using__(_opts) do
    quote do
      ucd = Advance.UCD.EmojiRegex.Parse.from_priv()
      emoji_regex = "^(?:#{Advance.UCD.EmojiRegex.emoji_sequence(ucd)})(?<rest>.*)"
      @emoji_regex Regex.compile!(emoji_regex, [:unicode, :extended])

      def next(string) do
        case Regex.run(@emoji_regex, string, capture: ["rest"]) do
          nil -> {nil, string}
          [rest] -> {2, rest}
        end
      end
    end
  end

  def emoji_sequence(ucd) do
    Enum.join(
      [
        emoji_zwj_sequence(ucd),
        emoji_tag_sequence(ucd),
        emoji_core_sequence(ucd)
      ],
      "|"
    )
    |> subpattern()
  end

  def emoji_core_sequence(ucd) do
    Enum.join(
      [
        emoji_flag_sequence(),
        emoji_modifier_sequence(ucd),
        emoji_keycap_sequence(),
        emoji_presentation_sequence(ucd),
        default_emoji_presentation_character(ucd)
      ],
      "|"
    )
    |> subpattern()
  end

  def emoji_zwj_sequence(ucd) do
    zwj = "\\x{200D}"

    "#{emoji_zwj_element(ucd)} (?: #{zwj} #{emoji_zwj_element(ucd)} )+"
    |> subpattern()
  end

  def emoji_tag_sequence(ucd) do
    tag_base = emoji_zwj_element(ucd)
    tag_spec = "[\\x{E0020}-\\x{E007E}]+"
    tag_end = "\\x{E007F}"

    Enum.join([tag_base, tag_spec, tag_end], " ")
    |> subpattern()
  end

  def emoji_keycap_sequence do
    "[0-9#*] (?: \\x{FE0F} \\x{20E3} | \\x{20E3} \\x{FE0F})"
    |> subpattern()
  end

  def emoji_presentation_sequence(ucd) do
    "#{emoji_character(ucd)} \\x{FE0F}"
    |> subpattern()
  end

  def emoji_modifier_sequence(ucd) do
    "#{emoji_modifier_base(ucd)} #{emoji_modifier(ucd)}"
    |> subpattern()
  end

  def emoji_flag_sequence do
    "#{regional_indicator()} #{regional_indicator()}"
    |> subpattern()
  end

  def emoji_zwj_element(ucd) do
    Enum.join(
      [
        emoji_modifier_sequence(ucd),
        emoji_presentation_sequence(ucd),
        emoji_character(ucd)
      ],
      "|"
    )
    |> subpattern()
  end

  def emoji_character(ucd) do
    to_regex_source(ucd.emoji)
  end

  def default_emoji_presentation_character(ucd) do
    to_regex_source(ucd.emoji_presentation)
  end

  def emoji_modifier_base(ucd) do
    to_regex_source(ucd.emoji_modifier_base)
  end

  def emoji_modifier(ucd) do
    to_regex_source(ucd.emoji_modifier)
  end

  def regional_indicator do
    to_regex_source([Range.new(0x1F1E6, 0x1F1FF)])
  end

  defp to_regex_source(ranges) do
    classes =
      ranges
      |> Stream.map(fn range ->
        {Integer.to_string(range.first, 16), Integer.to_string(range.last, 16)}
      end)
      |> Stream.map(fn {first, last} -> "\\x{#{first}}-\\x{#{last}}" end)
      |> Enum.join("")

    "[#{classes}]"
  end

  defp subpattern(pattern) do
    "(?:#{pattern})"
  end
end

defmodule Advance.UCD.EmojiRegex.Parse do
  def from_priv do
    stream =
      Path.join(:code.priv_dir(:advance), "ucd/emoji/emoji-data.txt")
      |> File.stream!()

    from_stream(stream)
  end

  def from_stream(stream) do
    stream
    |> Advance.UCD.Parse.trim()
    |> Stream.map(fn line ->
      [field_0, field_1] = String.split(line, ";", parts: 2)

      field_0 = String.trim(field_0)
      field_1 = Advance.UCD.Parse.trim(field_1)

      {parse_codepoints(field_0), parse_emoji_property(field_1)}
    end)
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
  end

  def parse_codepoints(raw) do
    {raw_first, raw_last} =
      case String.split(raw, "..") do
        [raw] ->
          {raw, raw}

        [raw_first, raw_last] ->
          {raw_first, raw_last}
      end

    Range.new(String.to_integer(raw_first, 16), String.to_integer(raw_last, 16))
  end

  def parse_emoji_property(raw) do
    raw_property =
      String.split(raw, " ", parts: 2)
      |> List.first()

    %{
      "Emoji" => :emoji,
      "Emoji_Presentation" => :emoji_presentation,
      "Emoji_Modifier" => :emoji_modifier,
      "Emoji_Modifier_Base" => :emoji_modifier_base,
      "Emoji_Component" => :emoji_component,
      "Extended_Pictographic" => :extended_pictographic
    }
    |> Map.fetch!(raw_property)
  end
end
