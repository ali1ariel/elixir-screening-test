defmodule ElixirInterviewStarter.CalibrationServer do
  use GenServer
  alias ElixirInterviewStarter.DeviceMessages
  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.DeviceMessages

  #API
  def start(email) do
    GenServer.start(__MODULE__, email, name: String.to_atom(email))
  end

  def get_current_session(email) when is_binary(email) do
    email
    |> String.to_atom()
    |> get_current_session()
  end

  def get_current_session(email) when is_atom(email) do
    GenServer.call(email, :get_current_session)
  end


  # Server
  @impl true
  def init(email) do
    {:ok, nil, {:continue, {:precheck_1, email}}}
  end

  @impl true
  def handle_continue({:precheck_1, email}, _state) do
    DeviceMessages.send(email, "startPrecheck1")
    {:noreply, %CalibrationSession{email: email, step: :precheck_1}}
  end

  @impl true
  def handle_call(:get_current_session, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_info( %{"precheck1" => true}, %CalibrationSession{step: :precheck_1} = state) do
    {:noreply, %CalibrationSession{state | step: :precheck1_success}}
  end
end
