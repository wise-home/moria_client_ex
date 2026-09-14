defmodule MoriaClient.Devices do
  alias MoriaClient.Common
  alias MoriaClient.Helpers

  def list_devices(client, opts) do
    url = "/api/v1/devices"
    req = [method: :get, url: url, query: Helpers.to_query(opts)]

    with {:ok, env} <- Common.request(client, req, [200]) do
      Helpers.to_schema(env.body, MoriaClient.Devices.DevicesPage)
    end
  end

  def stream_devices!(client, opts) do
    opts = Keyword.put_new(opts, :first, 50)

    Helpers.stream_pages(&list_devices(client, &1), opts)
    |> Stream.flat_map(& &1.devices)
  end

  def get_device(client, device_id) do
    url = "/api/v1/devices/#{device_id}"
    req = [method: :get, url: url]

    with {:ok, env} <- Common.request(client, req, [200]) do
      Helpers.to_schema(env.body["device"], MoriaClient.Devices.Device)
    end
  end

  def create_device(client, params) do
    url = "/api/v1/devices"
    req = [method: :post, url: url, body: %{device: params}]

    with {:ok, env} <- Common.request(client, req, [201]) do
      Helpers.to_schema(env.body["device"], MoriaClient.Devices.Device)
    end
  end

  def update_device(client, device_id, params) do
    url = "/api/v1/devices/#{device_id}"
    req = [method: :put, url: url, body: %{device: params}]

    with {:ok, env} <- Common.request(client, req, [200]) do
      Helpers.to_schema(env.body["device"], MoriaClient.Devices.Device)
    end
  end

  def delete_device(client, device_id) do
    url = "/api/v1/devices/#{device_id}"

    with {:ok, _env} <- Common.request(client, [method: :delete, url: url], [204]) do
      :ok
    end
  end
end
