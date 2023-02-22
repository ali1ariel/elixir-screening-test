defmodule ElixirInterviewStarter.Calibration.Application do
  def start(_args, _) do
    children = [
      ElixirInterviewStarter.DeviceServer
    ]


    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
