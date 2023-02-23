defmodule ElixirInterviewStarter.CalibrationServer do
  use GenServer
  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.DeviceMessages

  # API
  @timeout_precheck 30_000
  @timeout_calibrate 100_000

  @doc """
    Starts the GenServer with the given email as the name, allowing an only one server by device.
    Instantly, it continues to the precheck_1 phase.
  """
  @spec start(email :: String.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start(email) do
    GenServer.start(__MODULE__, email, name: String.to_atom(email))
  end

  @doc """
    It starts the precheck_2 phase, calling a callback that will dispatch the need process call, and will wait for the two responses,
    if everything's okay, starts the calibrate phase.s
  """
  @spec start_precheck_2(email :: String.t()) ::
          {:ok, CalibrationSession.t()} | {:error, :wrong_step}
  def start_precheck_2(email) do
    GenServer.call(String.to_atom(email), :precheck_2)
  end

  @doc """
    Get the current state of this server.
  """
  @spec get_current_session(email :: String.t()) :: {:ok, CalibrationSession.t()} | nil
  def get_current_session(email) when is_binary(email) do
    email
    |> String.to_atom()
    |> get_current_session()
  end

  @spec get_current_session(email :: atom) :: {:ok, CalibrationSession.t()} | nil
  def get_current_session(email) when is_atom(email) do
      GenServer.call(email, :get_current_session)
  end

  @spec get_current_session(pid :: pid) :: {:ok, CalibrationSession.t()} | nil
  def get_current_session(pid) when is_pid(pid) do
    try do
      GenServer.call(pid, :get_current_session)
    catch
      :exit, {:noproc, false} -> nil
    end
  end

  @impl true
  def init(email) do
    {:ok, nil, {:continue, {:precheck_1, email}}}
  end

  @impl true
  def handle_continue({:precheck_1, email}, _state) do
    DeviceMessages.send(email, "startPrecheck1")
    timer = Process.send_after(self(), :timeout, @timeout_precheck)
    {:noreply, %CalibrationSession{email: email, step: :precheck_1, timer: timer}}
  end

  @impl true
  def handle_call(:precheck_2, _from, %{step: :precheck1_success} = state) do
    DeviceMessages.send(state.email, "startPrecheck2")
    timer = Process.send_after(self(), :timeout, @timeout_precheck)
    state = %CalibrationSession{state | timer: timer}
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call(:precheck_2, _from, state) do
    {:reply, {:error, :wrong_step}, state}
  end

  @impl true
  def handle_call(:get_current_session, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_info(%{"precheck1" => true}, %CalibrationSession{step: :precheck_1} = state) do
    Process.cancel_timer(state.timer)
    {:noreply, %CalibrationSession{state | step: :precheck1_success}}
  end

  @impl true
  def handle_info(%{"precheck1" => false}, state) do
    Process.cancel_timer(state.timer)
    {:noreply, %CalibrationSession{state | step: :failed}}
  end

  @impl true
  def handle_info(%{"cartridgeStatus" => true}, %CalibrationSession{step: :precheck1_success} = state) do
    {:noreply, %CalibrationSession{state | step: :precheck2_half_complete}}
  end

  @impl true
  def handle_info(%{"submergedInWater" => true}, %CalibrationSession{step: :precheck1_success} = state) do
    {:noreply, %CalibrationSession{state | step: :precheck2_half_complete}}
  end

  @impl true
  def handle_info(
        %{"cartridgeStatus" => true},
        %CalibrationSession{step: :precheck2_half_complete} = state
      ) do
    Process.cancel_timer(state.timer)
    DeviceMessages.send(state.email, "calibrate")
    timer = Process.send_after(self(), :timeout, @timeout_calibrate)
    {:noreply, %CalibrationSession{state | step: :calibrating, timer: timer}}
  end

  @impl true
  def handle_info(
        %{"submergedInWater" => true},
        %CalibrationSession{step: :precheck2_half_complete} = state
      ) do
    Process.cancel_timer(state.timer)
    DeviceMessages.send(state.email, "calibrate")
    timer = Process.send_after(self(), :timeout, @timeout_calibrate)
    {:noreply, %CalibrationSession{state | step: :calibrating, timer: timer}}
  end

  @impl true
  def handle_info(%{"cartridgeStatus" => false}, state) do
    Process.cancel_timer(state.timer)
    {:noreply, %CalibrationSession{state | step: :failed}}
  end

  @impl true
  def handle_info(%{"submergedInWater" => false}, state) do
    Process.cancel_timer(state.timer)
    {:noreply, %CalibrationSession{state | step: :failed}}
  end

  @impl true
  def handle_info(%{"calibrated" => true}, state) do
    Process.cancel_timer(state.timer)
    {:noreply, %CalibrationSession{state | step: :completed}}
  end

  @impl true
  def handle_info(%{"calibrated" => false}, state) do
    Process.cancel_timer(state.timer)
    {:noreply, %CalibrationSession{state | step: :failed}}
  end

  @impl true
  def handle_info(:timeout, state), do: {:noreply, %CalibrationSession{state | step: :failed}}

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
