defmodule MoriaClientTest do
  use ExUnit.Case
  doctest MoriaClient

  describe "to_query" do
    test "to_query encodes an in filter with a list value" do
      query =
        MoriaClient.Helpers.to_query(
          filters: [%{field: :namespace_id, op: "in", value: [1, 2, 3]}]
        )

      assert Enum.sort(query) == [
               {"filters[0][field]", "namespace_id"},
               {"filters[0][op]", "in"},
               {"filters[0][value][]", "1"},
               {"filters[0][value][]", "2"},
               {"filters[0][value][]", "3"}
             ]
    end

    test "to_query empty list encodes as []=" do
      # since flop filters empty values from a list, we can just do an []=
      query =
        MoriaClient.Helpers.to_query(filters: [%{field: :namespace_id, op: "in", value: []}])

      assert Enum.sort(query) == [
               {"filters[0][field]", "namespace_id"},
               {"filters[0][op]", "in"},
               {"filters[0][value][]", ""}
             ]
    end
  end

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
