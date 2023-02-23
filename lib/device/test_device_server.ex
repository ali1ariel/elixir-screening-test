defmodule ElixirInterviewStarter.TestDeviceServer do
  @moduledoc false
  use GenServer

  def start_link(arg) do
    GenServer.start(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(arg), do: {:ok, arg}

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
