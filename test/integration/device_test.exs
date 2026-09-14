defmodule Integration.DeviceTest do
  use ExUnit.Case, async: true
  setup {Integration, :setup_client}
  setup {Integration, :setup_namespace}

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
