defmodule ElixirInterviewStarter do
  alias ElixirInterviewStarter.CalibrationServer
  @moduledoc """
  See `README.md` for instructions on how to approach this technical challenge.
  """

  alias ElixirInterviewStarter.CalibrationSession

  @spec start(user_email :: String.t()) :: {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Creates a new `CalibrationSession` for the provided user, starts a `GenServer` process
  for the session, and starts precheck 1.

  If the user already has an ongoing `CalibrationSession`, returns an error.
  """
  def start(user_email) do
    with {:ok, _pid} <- CalibrationServer.start(user_email) do
      get_current_session(user_email)
    else
      {:error, {:already_started, _pid}} -> {:error, "This device is already started."}
      _ -> {:error, "unknown error."}
    end
  end

  @spec start_precheck_2(user_email :: String.t()) ::
          {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Starts the precheck 2 step of the ongoing `CalibrationSession` for the provided user.

  If the user has no ongoing `CalibrationSession`, their `CalibrationSession` is not done
  with precheck 1, or their calibration session has already completed precheck 2, returns
  an error.
  """
  def start_precheck_2(user_email) do
    try do
      with {:ok, state} <- CalibrationServer.start_precheck_2(user_email) do
        {:ok, state}
      else
        {:error, :wrong_step} -> {:error, "That's the wrong step, probably you've run this again by mistake."}
        _ -> {:error, "unknown error."}
      end
    catch
      :exit, {:noproc, _} -> {:error, "This device is not started."}
    end
  end

  @spec get_current_session(user_email :: String.t()) :: {:ok, CalibrationSession.t() | nil}
  @doc """
  Retrieves the ongoing `CalibrationSession` for the provided user, if they have one
  """
  def get_current_session(user_email) do
    try do
      CalibrationServer.get_current_session(user_email)
    catch
      :exit, {:noproc, _} -> nil
    end
  end
end
