defmodule ElixirInterviewStarter.Application do
  @device_server Application.compile_env(:elixir_interview_starter, :device_server)

  def start(_args, _) do
    children = [
      @device_server
    ]


    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
