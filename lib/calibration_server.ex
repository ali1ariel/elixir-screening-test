defmodule ElixirInterviewStarter.CalibrationServer do
  use GenServer
  alias ElixirInterviewStarter.CalibrationSession


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
    {:ok, %CalibrationSession{email: email, step: :initiated}}
  end

  @impl true
  def handle_call(:get_current_session, _from, state) do
    {:reply, {:ok, state}, state}
  end
end
