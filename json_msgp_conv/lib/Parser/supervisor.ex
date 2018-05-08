defmodule JsonMsgpConv.Parser.Supervisor do
    use Supervisor

    alias JsonMsgpConv.Parser
    def start_link do
        Supervisor.start_link(__MODULE__,[])
    end

    def init(_) do
        children = [
            worker(Parser,[])
        ]

        supervise(children, strategy: :one_for_one)
    end
end