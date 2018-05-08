defmodule JsonMsgpConvTest do
  use ExUnit.Case
  doctest JsonMsgpConv

  test "greets the world" do
    assert JsonMsgpConv.hello() == :world
  end
end
