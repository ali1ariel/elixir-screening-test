defmodule ElixirInterviewStarter.CalibrationServer do
  use GenServer
  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.DeviceMessages

  #API
  @timeout_precheck 30_000
  @timeout_calibrate 100_000

  @spec start(email :: String.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start(email) do
    GenServer.start(__MODULE__, email, name: String.to_atom(email))
  end

  @spec start_precheck_2(email :: String.t()) :: {:ok, CalibrationSession.t()} | {:error, :wrong_step}
  def start_precheck_2(email) do
    GenServer.call(String.to_atom(email), :precheck_2)
  end

  @spec calibrate(email :: String.t()) ::  {:ok, CalibrationSession.t()} | {:error, :wrong_step} | {:error, any}
  def calibrate(email) do
    GenServer.call(String.to_atom(email), :calibrate)
  end

  @spec get_current_session(email :: String.t()) :: {:ok, CalibrationSession.t()}
  def get_current_session(email) when is_binary(email) do
    email
    |> String.to_atom()
    |> get_current_session()
  end

  @spec get_current_session(email :: atom) :: {:ok, CalibrationSession.t()}
  def get_current_session(email) when is_atom(email) do
    GenServer.call(email, :get_current_session)
  end

  @spec get_current_session(pid :: pid) :: {:ok, CalibrationSession.t()}
  def get_current_session(pid) when is_pid(pid) do
    GenServer.call(pid, :get_current_session)
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
    IO.inspect(state)
    DeviceMessages.send(state.email, "startPrecheck2")
    timer = Process.send_after(self(), :timeout, @timeout_precheck)
    state = %CalibrationSession{state | step: :precheck_2, timer: timer}
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call(:precheck_2, _from, state) do
    {:reply, {:error, :wrong_step}, state}
  end

  @impl true
  def handle_call(:calibrate, _from, %{step: :precheck2_complete} = state) do
    DeviceMessages.send(state.email, "calibrate")
    timer = Process.send_after(self(), :timeout, @timeout_calibrate)
    state =  %CalibrationSession{state | step: :calibrating, timer: timer}
    {:reply, state, state}
  end

    @impl true
    def handle_call(:get_current_session, _from, state) do
      {:reply, {:ok, state}, state}
    end

    @impl true
    def handle_info( %{"precheck1" => true}, %CalibrationSession{step: :precheck_1} = state) do
      Process.cancel_timer(state.timer)
      {:noreply, %CalibrationSession{state | step: :precheck1_success}}
    end
    @impl true
    def handle_info( %{"precheck1" => _}, state) do
      Process.cancel_timer(state.timer)
      {:noreply, %CalibrationSession{state | step: :failed}}
    end

    @impl true
    def handle_info(%{"cartridgeStatus" => true}, %CalibrationSession{step: :precheck_2} = state) do
      {:noreply, %CalibrationSession{state | step: :precheck2_half_complete}}
    end

    @impl true
    def handle_info(%{"submergedInWater" => true}, %CalibrationSession{step: :precheck_2} = state) do
      {:noreply, %CalibrationSession{state | step: :precheck2_half_complete}}
    end

    @impl true
    def handle_info(%{"cartridgeStatus" => true}, %CalibrationSession{step: :precheck2_half_complete} = state) do
      Process.cancel_timer(state.timer)
      DeviceMessages.send(state.email, "calibrate")
      timer = Process.send_after(self(), :timeout, @timeout_calibrate)
      state =  %CalibrationSession{state | step: :calibrating, timer: timer}
      {:noreply, state}
    end

    @impl true
    def handle_info(%{"submergedInWater" => true}, %CalibrationSession{step: :precheck2_half_complete} = state) do
      Process.cancel_timer(state.timer)
      DeviceMessages.send(state.email, "calibrate")
      timer = Process.send_after(self(), :timeout, @timeout_calibrate)
      state =  %CalibrationSession{state | step: :calibrating, timer: timer}
      {:noreply, state}
    end

    @impl true
    def handle_info(%{"cartridgeStatus" => _}, state) do
      Process.cancel_timer(state.timer)
      {:noreply, %CalibrationSession{state | step: :failed}}
    end

    @impl true
    def handle_info(%{"submergedInWater" => _}, state) do
      Process.cancel_timer(state.timer)
      {:noreply, %CalibrationSession{state | step: :failed}}
    end

    @impl true
    def handle_info(%{"calibrated" => true}, state) do
      Process.cancel_timer(state.timer)
      {:noreply, %CalibrationSession{state | step: :completed}}
    end

    @impl true
    def handle_info(%{"calibrated" => _}, state) do
      Process.cancel_timer(state.timer)
      {:noreply, %CalibrationSession{state | step: :failed}}
    end

    @impl true
    def handle_info(:timeout, state), do: {:noreply, %CalibrationSession{state | step: :failed}}
end
