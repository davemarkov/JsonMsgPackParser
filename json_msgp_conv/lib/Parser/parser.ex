defmodule JsonMsgpConv.Parser do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: :parser)
  end

  def init(_) do
    {:ok, :running}
  end

  def json_to_msgpack(input) do
    json_to_struct(input)
    |> struct_to_msgpack
  end

  def msgpack_to_json(input) do
    msgpack_to_struct(input)
    |> struct_to_json
  end

  def json_to_struct(input) do
    GenServer.call(:parser, {:decode, Json, input})
  end

  def struct_to_json(input) do
    GenServer.call(:parser, {:encode, Json, input})
  end

  def msgpack_to_struct(input) do
    GenServer.call(:parser, {:decode, MsgPack, input})
  end

  def struct_to_msgpack(input) do
    GenServer.call(:parser, {:encode, MsgPack, input})
  end

  # callbacks

  def handle_call({:encode, module, args}, _from, state) do
    encoded_data = StructFormat.encode!(module, args)
    {:reply, encoded_data, state}
  end

  def handle_call({:decode, module, args}, _from, state) do
    encoded_data = StructFormat.decode!(module, args)
    {:reply, encoded_data, state}
  end
end
