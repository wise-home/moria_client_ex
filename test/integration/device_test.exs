defmodule Integration.DeviceTest do
  use ExUnit.Case, async: true
  setup {Integration, :setup_client}
  setup {Integration, :setup_namespace}

  test "list devices with page pagination includes the total count", ctx do
    for index <- 1..2 do
      assert {:ok, _device} =
               MoriaClient.create_device(ctx.client, %{
                 namespace_id: ctx.namespace.id,
                 reference: "integration-test-device-#{ctx.machine.id}-#{index}"
               })
    end

    assert {:ok, page} =
             MoriaClient.list_devices(ctx.client,
               page: 1,
               page_size: 1,
               filters: [%{field: :namespace_id, value: ctx.namespace.id}]
             )

    assert [%{namespace_id: namespace_id}] = page.devices
    assert namespace_id == ctx.namespace.id
    assert page.page.total_count == 2
    assert page.page.has_next_page
  end

  test "list devices with an in filter", ctx do
    {:ok, namespace_2, _reference_2} = Integration.create_namespace(ctx)
    {:ok, namespace_3, _reference_3} = Integration.create_namespace(ctx)

    devices =
      for namespace <- [ctx.namespace, namespace_2, namespace_3] do
        assert {:ok, device} =
                 MoriaClient.create_device(ctx.client, %{
                   namespace_id: namespace.id,
                   reference: "integration-test-device-#{ctx.machine.id}-#{namespace.id}"
                 })

        device
      end

    assert {:ok, page} =
             MoriaClient.list_devices(ctx.client,
               first: 10,
               filters: [
                 %{field: :namespace_id, op: "in", value: [ctx.namespace.id, namespace_2.id]}
               ]
             )

    assert Enum.sort(Enum.map(page.devices, & &1.id)) ==
             devices |> Enum.take(2) |> Enum.map(& &1.id) |> Enum.sort()

    refute page.page.has_next_page
  end

  test "upsert creates a device and repeated calls update the same device", ctx do
    params = %{
      namespace_id: ctx.namespace.id,
      identification: "mbus::ELS:12345678:33:03",
      name: "Main meter",
      reference: "integration-test-device-#{ctx.machine.id}",
      description: "Meter near the entrance",
      metadata: [%{key: "site", value: "alpha"}]
    }

    assert {:ok, %MoriaClient.Devices.Device{} = device} =
             MoriaClient.upsert_device(ctx.client, params)

    assert device.namespace_id == params.namespace_id
    assert device.identification == params.identification
    assert device.name == params.name
    assert device.reference == params.reference
    assert device.description == params.description
    assert [%{key: "site", value: "alpha"}] = device.metadata

    assert {:ok, updated_device} =
             MoriaClient.upsert_device(ctx.client, %{
               namespace_id: params.namespace_id,
               identification: params.identification,
               description: "Updated"
             })

    assert updated_device.id == device.id
    assert updated_device.description == "Updated"
    assert updated_device.name == params.name
    assert updated_device.reference == params.reference

    assert {:ok, fetched_device} = MoriaClient.get_device(ctx.client, device.id)
    assert fetched_device.description == "Updated"

    assert {:ok, page} =
             MoriaClient.list_devices(ctx.client,
               first: 10,
               filters: [%{field: :namespace_id, value: ctx.namespace.id}]
             )

    assert Enum.map(page.devices, & &1.id) == [device.id]
  end

  test "upsert updates a device created through create_device", ctx do
    params = %{
      namespace_id: ctx.namespace.id,
      identification: "mbus::ELS:12345678:33:03"
    }

    assert {:ok, device} = MoriaClient.create_device(ctx.client, params)

    assert {:ok, updated_device} =
             MoriaClient.upsert_device(ctx.client, Map.put(params, :name, "Updated meter"))

    assert updated_device.id == device.id
    assert updated_device.name == "Updated meter"
  end

  test "upsert uses both namespace_id and identification as the identity", ctx do
    {:ok, other_namespace, _reference} = Integration.create_namespace(ctx)
    identification = "mbus::ELS:12345678:33:03"

    assert {:ok, device} =
             MoriaClient.upsert_device(ctx.client, %{
               namespace_id: ctx.namespace.id,
               identification: identification
             })

    assert {:ok, other_namespace_device} =
             MoriaClient.upsert_device(ctx.client, %{
               namespace_id: other_namespace.id,
               identification: identification
             })

    assert {:ok, other_identification_device} =
             MoriaClient.upsert_device(ctx.client, %{
               namespace_id: ctx.namespace.id,
               identification: "mbus::ELS:87654321:33:03"
             })

    assert other_namespace_device.namespace_id == other_namespace.id
    assert other_namespace_device.identification == identification
    assert other_identification_device.namespace_id == ctx.namespace.id
    assert other_identification_device.identification == "mbus::ELS:87654321:33:03"

    assert length(
             Enum.uniq([device.id, other_namespace_device.id, other_identification_device.id])
           ) ==
             3
  end

  test "upsert fails without both identity fields", ctx do
    for params <- [
          %{},
          %{namespace_id: ctx.namespace.id},
          %{identification: "mbus::ELS:12345678:33:03"}
        ] do
      assert {:error, _reason} = MoriaClient.upsert_device(ctx.client, params)
    end
  end

  test "devices CRUD", ctx do
    reference_1 = "integration-test-device-#{ctx.machine.id}-1"
    reference_2 = "integration-test-device-#{ctx.machine.id}-2"

    assert {:ok, device_1} =
             MoriaClient.create_device(ctx.client, %{
               namespace_id: ctx.namespace.id,
               name: "Main meter",
               reference: reference_1,
               identification: "mbus::ELS:12345678:33:03",
               description: "Meter near the entrance",
               metadata: [%{key: "site", value: "alpha"}]
             })

    assert device_1.reference == reference_1
    assert device_1.identification == "mbus::ELS:12345678:33:03"
    assert [%{key: "site", value: "alpha"}] = device_1.metadata

    assert {:ok, _device_2} =
             MoriaClient.create_device(ctx.client, %{
               namespace_id: ctx.namespace.id,
               reference: reference_2
             })

    assert {:ok, page_1} =
             MoriaClient.list_devices(ctx.client,
               first: 1,
               filters: [%{field: :namespace_id, value: ctx.namespace.id}]
             )

    assert page_1.page.has_next_page
    assert [%{reference: ^reference_1}] = page_1.devices

    assert {:ok, page_2} =
             MoriaClient.list_devices(ctx.client,
               first: 1,
               after: page_1.page.end_cursor,
               filters: [%{field: :namespace_id, value: ctx.namespace.id}]
             )

    refute page_2.page.has_next_page
    assert [%{reference: ^reference_2}] = page_2.devices

    assert [
             %{reference: ^reference_1},
             %{reference: ^reference_2}
           ] =
             MoriaClient.stream_devices!(ctx.client,
               first: 1,
               filters: [%{field: :namespace_id, value: ctx.namespace.id}]
             )
             |> Enum.to_list()

    assert {:ok, updated_device} =
             MoriaClient.update_device(ctx.client, device_1.id, %{description: "Updated"})

    assert updated_device.description == "Updated"

    assert {:ok, fetched_device} = MoriaClient.get_device(ctx.client, device_1.id)
    assert fetched_device.id == device_1.id
    assert fetched_device.reference == reference_1

    assert :ok = MoriaClient.delete_device(ctx.client, device_1.id)
    assert {:error, _reason} = MoriaClient.get_device(ctx.client, device_1.id)
  end
end
