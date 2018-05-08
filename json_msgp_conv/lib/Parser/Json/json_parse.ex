defmodule Json do
  @behaviour StructFormat
  
  def encode(result_pair) do
    res = encode_value(result_pair)  
    IO.iodata_to_binary(res)
  end
  defp encode_value({:object, list}) do
    res = encode_object(list, "")
    ["{", res]
  end

  defp encode_value({:array, list}) do
    res = encode_array(list, "")
    ["[", res]
  end

  defp encode_value(string) when is_binary(string) do
    encode_string(string)
  end

  defp encode_value(number) when is_number(number) do
    encode_number(number)
  end

  defp encode_value(true), do: "true"
  defp encode_value(false), do: "false"
  defp encode_value(nil), do: "null"

  defp encode_object([], res), do: res

  defp encode_object([{str, val}], res) do
    encode_object([], [res, encode_string(str), ":", encode_value(val), "}"])
  end

  defp encode_object([{str, val} | rest], res) do
    encode_object(rest, [res, encode_string(str), ":", encode_value(val), ","])
  end

  defp encode_string(string) do
    ["\"", string, "\""]
  end

  defp encode_number(number) when is_float(number) do
    Float.to_string(number)
  end

  defp encode_number(number) when is_integer(number) do
    Integer.to_string(number)
  end

  defp encode_array([], res), do: res

  defp encode_array([head], res) do
    encode_array([], [res, encode_value(head), "]"])
  end

  defp encode_array([head | tail], res) do
    encode_array(tail, [res, encode_value(head), ","])
  end

  
  #decode
  def decode(string) do
    {parsed,_} = parse_value(string)
    parsed
  end

  defp skip_whitespaces(<<>>), do: ""

  defp skip_whitespaces(<<byte, rest::binary>>) when byte in ' \n\f\b\r\t' do
    skip_whitespaces(rest)
  end

  defp skip_whitespaces(string), do: string

  defp parse_value(<<"{", rest::binary>>) do
    case skip_whitespaces(rest) do
      <<"}", rest::binary>> -> complete_object(rest, []) 
      _ -> parse_object(rest, [])
    end
  end

  defp parse_value(<<"[", rest::binary>>) do
    case skip_whitespaces(rest) do
      <<"]", rest::binary>> -> complete_array(rest, []) 
      _ -> parse_array(rest, [])
    end
  end

  defp parse_value(<<"\"", rest::binary>>) do
    parse_string(rest, [])
  end

  defp parse_value(<<digit, _rest::binary>> = string) when digit in '-0123456789' do
    parse_number(string, [])
  end

  defp parse_value(<<"true", rest::binary>>), do: {true, rest}
  defp parse_value(<<"false", rest::binary>>), do: {false, rest}
  defp parse_value(<<"null", rest::binary>>), do: {nil, rest}
  defp parse_value(string), do: {:error, string}

  defp complete_array(string, res) do
    {{:array, Enum.reverse(res)}, string}
  end

  defp parse_array(string, res) do
    {val, rest} =
      string
      |> skip_whitespaces
      |> parse_value

    case skip_whitespaces(rest) do
      <<",", rest::binary>> ->
        skip_whitespaces(rest)
        |> parse_array([val | res])

      <<"]", rest::binary>> ->
        complete_array(rest, [val | res])

      _ ->
        {:error, {:array, Enum.reverse(res)}}
    end
  end

  defp complete_object(string, res) do
    {{:object, Enum.reverse(res)}, string}
  end

  defp parse_object(string, res) do
    {pair1, rest} =
      case skip_whitespaces(string) do
        <<"\"", rest::binary>> -> parse_string(rest, "")
        _ -> {:error, {:object,:string, Enum.reverse(res)}}
      end

    {pair2, rest} =
      case skip_whitespaces(rest) do
        <<":", rest::binary>> ->
          skip_whitespaces(rest)
          |> parse_value

        _ ->
          {:error, {:object,:middle, Enum.reverse(res)}}
      end

    case skip_whitespaces(rest) do
      <<",", rest::binary>> ->
        parse_object(rest, [{pair1, pair2} | res])

      <<"}", rest::binary>> ->
        complete_object(rest, [{pair1, pair2} | res])

      _ ->
        {:error, rest}
    end
  end

  # string

  defp parse_string(<<"\\", byte, rest::binary>>, res)
      when byte in ["b", "f", "n", "r", "t", "u"] do
    parse_string(rest, res <> parse_symbols(byte))
  end

  defp parse_string(<<"\"", rest::binary>>, res) do
    {IO.iodata_to_binary(res), rest}
  end

  defp parse_string(<<char, rest::binary>>, res) do
    parse_string(rest, [res, char])
  end

  defp parse_string("", res) do
    {:error, Enum.take(res,8)}
  end

  defp parse_symbols("b"), do: "\b"
  defp parse_symbols("n"), do: "\n"
  defp parse_symbols("f"), do: "\f"
  defp parse_symbols("r"), do: "\r"
  defp parse_symbols("t"), do: "\t"
  # def parse_symbols("u"), do: "\u"
  defp parse_symbols(char), do: char

  # number
  defp parse_number(<<"-", rest::binary>>, res) do
    parse_number(rest, [res, "-"])
  end

  defp parse_number(<<digit, rest::binary>>, res)
      when digit in '123456789' do
    parse_integer(rest, [res, digit])
  end

  defp parse_number(<<"0", rest::binary>>, res) do
    case rest do
      <<".", rest::binary>> -> parse_float(rest, [res, "0."])
      _ -> {String.to_integer("0"), rest}
    end
  end

  defp parse_number(string,res) do
    {IO.iodata_to_binary(res) |> String.to_integer(), string}
  end

  defp parse_integer(<<digit, rest::binary>>, res)
      when digit in '0123456789' do
    parse_integer(rest, [res, digit])
  end

  defp parse_integer(<<".", rest::binary>>, res) do
    parse_float(rest, [res, "."])
  end

  defp parse_integer(string, res) do
    {IO.iodata_to_binary(res) |> String.to_integer(), string}
  end

  defp parse_float(<<digit, rest::binary>>, res)
      when digit in '0123456789' do
    parse_float(rest, [res, digit])
  end

  defp parse_float(<<byte, rest::binary>>, res) when byte in 'eE' do
    case rest do
      <<"+", rest::binary>> -> parse_float(rest, [res, byte, "+"])
      <<"-", rest::binary>> -> parse_float(rest, [res, byte, "-"])
      _ -> parse_float(rest, [res, byte])
    end
  end

  defp parse_float(string, res) do
    {IO.iodata_to_binary(res) |> String.to_float(), string}
  end
end