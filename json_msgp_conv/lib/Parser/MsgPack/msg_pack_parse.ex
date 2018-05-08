defmodule MsgPack do
  @behaviour StructFormat

  def encode(val) do
    encode_value(val)
  end

  defp encode_value(value) when is_atom(value), do: encode_atom(value)
  defp encode_value(value) when is_binary(value), do: encode_string(value)
  defp encode_value(value) when is_number(value), do: encode_number(value)
  defp encode_value({:object, list}), do: encode_object(list)
  defp encode_value({:array, list}), do: encode_array(list)

  # string

  defp encode_atom(nil), do: <<0xC0>>
  defp encode_atom(false), do: <<0xC2>>
  defp encode_atom(true), do: <<0xC3>>
  defp encode_atom(string), do: {:error, string}

  defp encode_string(string) do
    size = String.length(string)
    encode_string(<<size::32>>, string)
  end

  defp encode_string(<<0::24, 0::3, size::5>>, str) do
    <<0b101::3, size::5>> <> str
  end

  defp encode_string(<<0::24, size::8>>, str) do
    <<0xD9, size::8>> <> str
  end

  defp encode_string(<<0::16, size::16>>, str) do
    <<0xDA, size::16>> <> str
  end

  defp encode_string(<<size::32>>, str) do
    <<0xDB, size::32>> <> str
  end

  defp encode_string(_num, string), do: {:error, string}

  # number
  defp encode_number(number) when is_integer(number) do
    encode_integer(<<number::64>>)
  end

  defp encode_integer(<<0::32, 0::24, 0::1, size::unsigned-integer-size(7)>>) do
    <<0b0::1, size::unsigned-integer-size(7)>>
  end

  defp encode_integer(<<0::32, 0::24, 0::3, size::signed-integer-size(5)>>) do
    <<0b111::3, size::signed-integer-size(5)>>
  end

  defp encode_integer(<<0::32, 0::24, size::signed-integer-size(8)>>) do
    <<0xD0, size::signed-integer-size(8)>>
  end

  defp encode_integer(<<0::32, 0::16, size::signed-integer-size(16)>>) do
    <<0xD1, size::signed-integer-size(16)>>
  end

  defp encode_integer(<<0::32, size::signed-integer-size(32)>>) do
    <<0xD2, size::signed-integer-size(32)>>
  end

  defp encode_integer(<<size::signed-integer-size(64)>>) do
    <<0xD3, size::signed-integer-size(64)>>
  end

  defp encode_integer(string), do: {:error, string}

  # array
  defp encode_array(list) do
    len = Enum.count(list)
    array_header = encode_array_length(<<len::32>>)
    encode_array(list, array_header)
  end

  defp encode_array([], res), do: res

  defp encode_array([val | rest], res) do
    encoded_val = encode_value(val)
    encode_array(rest, res <> encoded_val)
  end

  defp encode_array_length(<<0::24, 0::4, size::4>>) do
    <<0b1001::4, size::4>>
  end

  defp encode_array_length(<<0::16, size::16>>) do
    <<0xDC, size::16>>
  end

  defp encode_array_length(<<size::32>>) do
    <<0xDD, size::32>>
  end

  defp encode_array_length(_num), do: {:error}

  # object
  defp encode_object(list) do
    len = Enum.count(list)
    object_header = encode_object_length(<<len::32>>)
    encode_object(list, object_header)
  end

  defp encode_object([], res), do: res

  defp encode_object([{str, val} | rest], res) do
    encoded_str = encode_string(str)
    encoded_val = encode_value(val)
    encode_object(rest, res <> encoded_str <> encoded_val)
  end

  defp encode_object_length(<<0::24, 0::4, size::4>>) do
    <<0b1000::4, size::4>>
  end

  defp encode_object_length(<<0::16, size::16>>) do
    <<0xDE, size::16>>
  end

  defp encode_object_length(<<size::32>>) do
    <<0xDF, size::32>>
  end

  defp encode_object_length(_num), do: {:error}

  # decode
  def decode(string) do
    {res, _} = parse_value(string)
    res
  end

  defp parse_value(<<byte, _rest::binary>> = string)
       when byte in 0b10100000..0b10111111 or byte in [0xD9, 0xDA, 0xDB] do
    parse_string(string)
  end

  defp parse_value(<<byte, _rest::binary>> = number)
       when byte in 0b00000000..0b01111111 or byte in 0b11100000..0b11111111 or byte in 0xCC..0xD3 do
    parse_number(number)
  end

  defp parse_value(<<byte, _rest::binary>> = atom)
       when byte in [0xC0, 0xC2, 0xC3] do
    parse_atom(atom)
  end

  defp parse_value(<<byte, _rest::binary>> = array)
       when byte in 0b10010000..0b10011111 or byte in [0xDC, 0xDD] do
    parse_array(array)
  end

  defp parse_value(<<byte, _rest::binary>> = object)
       when byte in 0b10000000..0b10001111 or byte in [0xDE, 0xDF] do
    parse_object(object)
  end
  defp parse_value(_string) do
    {:error,:value}
  end

  defp parse_atom(<<0xC0, rest::binary>>), do: {nil, rest}
  defp parse_atom(<<0xC2, rest::binary>>), do: {false, rest}
  defp parse_atom(<<0xC3, rest::binary>>), do: {true, rest}

  # fixstr
  defp parse_string(<<0b101::3, num::5, rest::binary>>) do
    <<string::bytes-size(num), rest::binary>> = rest
    {string, rest}
  end

  # str
  defp parse_string(<<0xD9, num::8, rest::binary>>) do
    <<string::bytes-size(num), rest::binary>> = rest
    {string, rest}
  end

  defp parse_string(<<0xDA, num::16, rest::binary>>) do
    <<string::bytes-size(num), rest::binary>> = rest
    {string, rest}
  end

  defp parse_string(<<0xDB, num::32, rest::binary>>) do
    <<string::bytes-size(num), rest::binary>> = rest
    {string, rest}
  end

  defp parse_string(<<_byte, num::32,_rest::binary>>), do: {:error, {:string,num}}

  defp parse_number(string) do
    parse_integer(string) || nil
  end

  # fixnum
  defp parse_integer(<<0b0::1, res::7, rest::binary>>), do: {res, rest}
  defp parse_integer(<<0b111::3, res::5, rest::binary>>), do: {res * -1, rest}

  # uint
  defp parse_integer(<<0xCC, res::8, rest::binary>>), do: {res, rest}
  defp parse_integer(<<0xCD, res::16, rest::binary>>), do: {res, rest}
  defp parse_integer(<<0xCE, res::32, rest::binary>>), do: {res, rest}
  defp parse_integer(<<0xCF, res::64, rest::binary>>), do: {res, rest}

  # int
  defp parse_integer(<<0xD0, 0b0::1, num::7, rest::binary>>), do: {num, rest}
  defp parse_integer(<<0xD0, 0b1::1, num::7, rest::binary>>), do: {num * -1, rest}
  defp parse_integer(<<0xD1, 0b0::1, num::15, rest::binary>>), do: {num, rest}
  defp parse_integer(<<0xD1, 0b1::1, num::15, rest::binary>>), do: {num * -1, rest}
  defp parse_integer(<<0xD2, 0b0::1, num::31, rest::binary>>), do: {num, rest}
  defp parse_integer(<<0xD2, 0b1::1, num::31, rest::binary>>), do: {num * -1, rest}
  defp parse_integer(<<0xD3, 0b0::1, num::63, rest::binary>>), do: {num, rest}
  defp parse_integer(<<0xD3, 0b1::1, num::63, rest::binary>>), do: {num * -1, rest}
  defp parse_integer(<<_byte, num::64,_rest::binary>>), do: {:error, {:number,num}}

  # def parse_float(<<0xca,)

  # array
  defp parse_array(<<0b1001::4, size::4, rest::binary>>) do
    parse_array(size, rest, [])
  end

  defp parse_array(<<0xDC, size::16, rest::binary>>) do
    parse_array(size, rest, [])
  end

  defp parse_array(<<0xDD, size::32, rest::binary>>) do
    parse_array(size, rest, [])
  end

  defp parse_array(<<_byte,size::32,_rest::binary>>), do: {:error,{:array,size}}

  defp parse_array(0, string, res), do: {{:array, Enum.reverse(res)}, string}

  defp parse_array(size, string, res) do
    {value, rest} = parse_value(string)
    parse_array(size - 1, rest, [value | res])
  end

  # object
  defp parse_object(<<0b1000::4, size::4, rest::binary>>) do
    parse_object(size, rest, [])
  end

  defp parse_object(<<0xDE, size::16, rest::binary>>) do
    parse_object(size, rest, [])
  end

  defp parse_object(<<0xDF, size::32, rest::binary>>) do
    parse_object(size, rest, [])
  end

  defp parse_object(<<_byte,size::32,_rest::binary>>), do: {:error,{:array,size}}

  defp parse_object(0, string, res), do: {{:object, Enum.reverse(res)}, string}

  defp parse_object(size, string, res) do
    {str, rest} = parse_string(string)
    {val, rest} = parse_value(rest)
    parse_object(size - 1, rest, [{str, val} | res])
  end
end
