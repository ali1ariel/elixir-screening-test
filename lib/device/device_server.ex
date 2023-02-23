defmodule ElixirInterviewStarter.DeviceServer do
  @moduledoc false
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

  @impl true
  def handle_info({email, "startPrecheck2"}, state) do
    Process.send(String.to_atom(email), %{"submergedInWater" => true}, [])
    Process.send(String.to_atom(email), %{"cartridgeStatus" => true}, [])
    {:noreply, state}
  end

  @impl true
  def handle_info({email, "calibrate"}, state) do
    Process.send(String.to_atom(email), %{"calibrated" => true}, [])
    {:noreply, state}
  end
end
