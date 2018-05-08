defmodule Json.ErrorHandler do
    def message({:decode,:value}) do
        "Incomplete. Expexted value"
    end
    def message({:decode,{:array,list}}) do
        "Incomplete array: #{list}. Expected ',' or ']'"
    end
    def message({:decode,{:object,:string, list}}) do
        "Missing string in pair in object: #{list}. Expected string"
    end
    def message({:decode,{:object,:middle, list}}) do
        "Incomplete pair in object: #{list}. Expected ':'"
    end
    def message({:decode,{:object,:end, list}}) do
        "Incomplete object: #{list}. Expected ',' or '}'"
    end
    def message({:decode,number}) when is_number(number) do

    end
    def message({:decode,string}) when is_binary(string) do
        "Incomplete string: #{string}. Expected '\"'" 
    end
end