defmodule Advance.UCD.UnicodeDataTest do
  use ExUnit.Case

  alias Advance.UCD.UnicodeData

  test "UnicodeData.Parse.from_priv" do
    data = UnicodeData.Parse.from_priv()

    assert MapSet.size(data) > 0
  end
end
