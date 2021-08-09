defmodule Advance.UCD.Parse do
  def trim(raw) when is_binary(raw) do
    raw
    |> String.replace(~r/#.*$/, "")
    |> String.trim()
  end

  def trim(stream) do
    stream
    |> Stream.map(fn line -> String.trim(line) end)
    |> Stream.reject(fn line -> line == "" end)
    |> Stream.reject(fn line -> String.starts_with?(line, "#") end)
  end
end
