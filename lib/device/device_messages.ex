defmodule ElixirInterviewStarter.DeviceMessages do
  @moduledoc """
  You shouldn't need to mofidy this module.

  This module provides an interface for mock-sending commands to devices.
  """
  @device_server Application.compile_env(:elixir_interview_starter, :device_server)

  @spec send(user_email :: String.t(), command :: String.t()) :: :ok
  @doc """
  Pretends to send the provided command to the Sutro Smart Monitor belonging to the
  provided user, which for the purposes of this challenge will always succeed.
  """

  def send(user_email, command) do
    Process.send(@device_server, {user_email, command}, [])
  end
end
