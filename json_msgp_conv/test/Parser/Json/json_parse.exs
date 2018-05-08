defmodule Json.Test do
  use ExUnit.Case
  #doctest Json
  alias JsonMsgpConv.Parser

  test "object and array" do
    Parser.start_link()
    parsed = Parser.json_to_struct("{\"compact\":true,\"schema\": [true, 23432, \"qweqweqwe\"]}")

    assert parsed ==
             {:object, [{"compact", true}, {"schema", {:array, [true, 23432, "qweqweqwe"]}}]}
  end

  test "empty object and array" do
    Parser.start_link()
    parsed = Parser.json_to_struct("{\"compact\":true,\"schema\": [true, 23432, \"qweqweqwe\"]}")

    assert parsed == {:object, []}

    parsed = Parser.json_to_struct("{\"compact\":true,\"schema\": []}")
    assert parsed ==
             {:object, [{"compact", true}, {"schema", {:array, []}}]}
  end

  test "string" do
    Parser.start_link()
    parsed = Parser.json_to_struct("{\"compact\":true,\"sch\"ema\": [true, 23432, \"qweqweqwe\"]}")

    assert parsed == :error
  end
end
