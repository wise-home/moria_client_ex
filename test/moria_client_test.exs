defmodule MoriaClientTest do
  use ExUnit.Case
  doctest MoriaClient

  test "casts component response errors into error schemas" do
    assert {:ok, response} =
             MoriaClient.Messages.ComponentResponse.changeset(%{
               results: %{},
               errors: %{
                 "debug" => [
                   %{"message" => "failed", "code" => "invalid"},
                   %{"message" => "timed out", "code" => "timeout"}
                 ]
               }
             })
             |> Ecto.Changeset.apply_action(:validate_server_response)

    assert %{
             "debug" => [
               %MoriaClient.Messages.ComponentResponseError{
                 message: "failed",
                 code: "invalid"
               },
               %MoriaClient.Messages.ComponentResponseError{
                 message: "timed out",
                 code: "timeout"
               }
             ]
           } = response.errors
  end
end
