defmodule AdvanceTest do
  use ExUnit.Case
  doctest Advance

  test "of" do
    assert Advance.of("7⃣") == 1
    assert Advance.of("8⃣️7⃣️") == 4
    assert Advance.of("🔬") == 2
    assert Advance.of("👩‍🔬") == 2
    assert Advance.of("字") == 2
    assert Advance.of("ｱ") == 1
    assert Advance.of("ア") == 2
    assert Advance.of("Ä") == 1
  end
end
