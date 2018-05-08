defmodule StructFormat do
    @type struct_list :: {binary, value} | value
    @type struct_type :: :object | :array
    @type structure ::  {struct_type, struct_list}
    @type value :: nil | true | false | structure | binary | number

    @callback encode(value) :: binary
    @callback decode(binary) :: value | :error

    def encode!(module,arg) do
        module.encode(arg)
    end

    def decode!(module,arg) do
        module.decode(arg)
    end
end