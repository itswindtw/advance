defmodule Advance.Hardcoded do
  def next(<<_::utf8, rest::binary>>), do: {1, rest}
end
