defmodule ElixirInterviewStarterTest do
  use ExUnit.Case, async: true
  doctest ElixirInterviewStarter
  alias ElixirInterviewStarter.CalibrationSession

  # For test porpuses, we won't test the Module ElixirInterviewStarter itself, because the singleton characteristics, the async behaviour, and other points. We are testing the GenServer receive functions, and if they are producing the wanted result in get_current_session. The flux works perfectly in IEX because's the time user input.

  test "it can go through the whole flow happy path" do
    # Firstly, we set a unique device id.
    email = "user_" <> random_string(5) <> "@device.com"
    device = String.to_atom(email)

    # Here's we assert that the GenServer starts correctly.
    assert {:ok, %CalibrationSession{}} = ElixirInterviewStarter.start(email)

    # One of the conditions in handle_continue of the GenServer init is receive this response from the device.
    Process.send(device, %{"precheck1" => true}, [])

    # Finally, we assert that we are in the correct step.
    assert {:ok, %CalibrationSession{step: :precheck1_success}} =
             ElixirInterviewStarter.get_current_session(email)

    # Receive the 2 responses for precheck 2
    Process.send(device, %{"cartridgeStatus" => true}, [])
    Process.send(device, %{"submergedInWater" => true}, [])

    assert {:ok, %CalibrationSession{step: :calibrating}} =
             ElixirInterviewStarter.get_current_session(email)

    # The last response from the device server
    Process.send(device, %{"calibrated" => true}, [])

    assert {:ok, %CalibrationSession{step: :completed}} =
             ElixirInterviewStarter.get_current_session(email)
  end

  test "start/1 creates a new calibration session and starts precheck 1" do
    email = "user_" <> random_string(5) <> "@device.com"
    device = String.to_atom(email)

    {:ok, %CalibrationSession{}} = ElixirInterviewStarter.start(email)
    Process.send(device, %{"precheck1" => true}, [])

    assert {:ok, %CalibrationSession{step: :precheck1_success}} =
             ElixirInterviewStarter.get_current_session(email)
  end

  test "start/1 returns an error if the provided user already has an ongoing calibration session" do
    email = "user_" <> random_string(5) <> "@device.com"

    assert {:ok, %CalibrationSession{email: email}} = ElixirInterviewStarter.start(email)
    assert {:error, "This device is already started."} = ElixirInterviewStarter.start(email)
  end

  test "start_precheck_2/1 returns an error if the provided user does not have an ongoing calibration session" do
    email = "user_" <> random_string(5) <> "@device.com"

    assert {:error, "This device is not started."} =
             ElixirInterviewStarter.start_precheck_2(email)
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is not done with precheck 1" do
    email = "user_" <> random_string(5) <> "@device.com"

    ElixirInterviewStarter.start(email)

    assert {:error, "That's the wrong step, probably you've run this again by mistake."} =
             ElixirInterviewStarter.start_precheck_2(email)
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is already done with precheck 2" do
    email = "user_" <> random_string(5) <> "@device.com"
    device = String.to_atom(email)

    {:ok, %CalibrationSession{}} = ElixirInterviewStarter.start(email)
    Process.send(device, %{"precheck1" => true}, [])
    Process.send(device, %{"cartridgeStatus" => true}, [])
    Process.send(device, %{"submergedInWater" => true}, [])
    Process.send(device, %{"calibrated" => true}, [])

    assert {:ok, %CalibrationSession{step: :completed}} =
             ElixirInterviewStarter.get_current_session(email)

    assert {:error, "That's the wrong step, probably you've run this again by mistake."} =
             ElixirInterviewStarter.start_precheck_2(email)
  end

  test "get_current_session/1 returns nil if the provided user has no ongoing calibrationo session" do
    email = "user_" <> random_string(5) <> "@device.com"

    assert is_nil(ElixirInterviewStarter.get_current_session(email))
  end

  defp random_string(qtde),
    do: for(_ <- 1..qtde, into: "", do: <<Enum.random('0123456789abcdefghijklmnopqrstuvwxyz')>>)
end
