defmodule MoriaClient.DevicesTest do
  use ExUnit.Case, async: true

  test "upsert patches the devices collection and casts the response" do
    params = %{
      namespace_id: "namespace-1",
      identification: "mbus::ELS:12345678:33:03",
      name: "Main meter",
      metadata: [%{key: "site", value: "alpha"}]
    }

    client =
      MoriaClient.client(
        adapter: fn env ->
          assert env.method == :patch
          assert env.url == "http://localhost:4000/api/v1/devices"
          assert JSON.decode!(env.body) == JSON.decode!(JSON.encode!(%{device: params}))

          {:ok,
           %{
             env
             | status: 200,
               headers: [{"content-type", "application/json"}],
               body: JSON.encode!(%{device: Map.put(params, :id, "device-1")})
           }}
        end
      )

    assert {:ok, %MoriaClient.Devices.Device{} = device} =
             MoriaClient.upsert_device(client, params)

    assert device.id == "device-1"
    assert device.namespace_id == params.namespace_id
    assert device.identification == params.identification
    assert device.name == params.name
    assert [%MoriaClient.Common.Metadata{key: "site", value: "alpha"}] = device.metadata
  end

  test "upsert returns API validation errors" do
    client =
      MoriaClient.client(
        adapter: fn env ->
          {:ok,
           %{
             env
             | status: 422,
               headers: [{"content-type", "application/json"}],
               body: JSON.encode!(%{errors: %{identification: ["can't be blank"]}})
           }}
        end
      )

    assert {:error,
            %MoriaClient.Errors.Unprocessable{
              errors: [
                %MoriaClient.Common.FieldError{
                  field: "identification",
                  reason: "can't be blank"
                }
              ]
            }} = MoriaClient.upsert_device(client, %{namespace_id: "namespace-1"})
  end

  test "upsert returns response-validation changesets" do
    client =
      MoriaClient.client(
        adapter: fn env ->
          {:ok,
           %{
             env
             | status: 200,
               headers: [{"content-type", "application/json"}],
               body: JSON.encode!(%{device: %{inserted_at: "invalid"}})
           }}
        end
      )

    assert {:error, %Ecto.Changeset{valid?: false} = changeset} =
             MoriaClient.upsert_device(client, %{
               namespace_id: "namespace-1",
               identification: "mbus::ELS:12345678:33:03"
             })

    assert Keyword.has_key?(changeset.errors, :inserted_at)
  end

  test "upsert returns transport errors" do
    error = %Mint.TransportError{reason: :econnrefused}
    client = MoriaClient.client(adapter: fn _env -> {:error, error} end)

    assert {:error, ^error} =
             MoriaClient.upsert_device(client, %{
               namespace_id: "namespace-1",
               identification: "mbus::ELS:12345678:33:03"
             })
  end

  test "upsert returns timeout errors" do
    client = MoriaClient.client(adapter: fn _env -> {:error, :timeout} end)

    assert {:error, :timeout} =
             MoriaClient.upsert_device(client, %{
               namespace_id: "namespace-1",
               identification: "mbus::ELS:12345678:33:03"
             })
  end

  test "upsert returns JSON decoding errors" do
    client =
      MoriaClient.client(
        adapter: fn env ->
          {:ok,
           %{
             env
             | status: 200,
               headers: [{"content-type", "application/json"}],
               body: "{"
           }}
        end
      )

    assert {:error, {Tesla.Middleware.JSON, :decode, {:unexpected_end, 1}}} =
             MoriaClient.upsert_device(client, %{
               namespace_id: "namespace-1",
               identification: "mbus::ELS:12345678:33:03"
             })
  end
end
