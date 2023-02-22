defmodule ElixirInterviewStarter.DeviceServer do
  use GenServer

  def start_link(arg) do
    GenServer.start(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(arg), do: {:ok, arg}

  @impl true
  def handle_info({email, "startPrecheck1"}, state) do
    Process.send(String.to_atom(email), %{"precheck1" => true}, [])
    {:noreply, state}
  end
end
