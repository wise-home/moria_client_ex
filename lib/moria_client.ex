defmodule MoriaClient do
  @moduledoc """
  Documentation for `MoriaClient`.
  """

  @type error ::
          MoriaClient.Errors.BadRequest.t()
          | MoriaClient.Errors.Unauthorized.t()
          | MoriaClient.Errors.Forbidden.t()
          | MoriaClient.Errors.NotFound.t()
          | MoriaClient.Errors.Conflict.t()
          | MoriaClient.Errors.InternalServerError.t()

  @type t :: Tesla.Client.t()

  ##
  ## Machines
  ##
  defdelegate get_machine(client, machine_id), to: MoriaClient.Machines
  defdelegate create_machine(client, params), to: MoriaClient.Machines
  defdelegate update_machine(client, id, params), to: MoriaClient.Machines
  defdelegate delete_machine(client, id), to: MoriaClient.Machines

  ##
  ## Namespaces
  ##
  defdelegate list_namespaces(client, opts \\ []), to: MoriaClient.Namespaces
  defdelegate stream_namespaces!(client, opts \\ []), to: MoriaClient.Namespaces
  defdelegate get_namespace(client, namespace_id), to: MoriaClient.Namespaces
  defdelegate create_namespace(client, params), to: MoriaClient.Namespaces
  defdelegate delete_namespace(client, id), to: MoriaClient.Namespaces

  ##
  ## Topics
  ##
  defdelegate list_topics(client, opts \\ []), to: MoriaClient.Topics
  defdelegate stream_topics!(client, opts \\ []), to: MoriaClient.Topics
  defdelegate get_topic(client, topic_id), to: MoriaClient.Topics

  @deprecated "use list_devices/2 instead"
  defdelegate get_topic_device_summary(client, topic_id, opts \\ []), to: MoriaClient.Topics

  defdelegate create_topic(client, params), to: MoriaClient.Topics
  defdelegate update_topic(client, topic_id, params), to: MoriaClient.Topics
  defdelegate delete_topic(client, topic_id), to: MoriaClient.Topics

  ##
  ## Devices
  ##

  defdelegate list_devices(client, opts \\ []), to: MoriaClient.Devices
  defdelegate stream_devices!(client, opts \\ []), to: MoriaClient.Devices
  defdelegate get_device(client, device_id), to: MoriaClient.Devices
  defdelegate create_device(client, params), to: MoriaClient.Devices
  defdelegate update_device(client, device_id, params), to: MoriaClient.Devices
  defdelegate delete_device(client, device_id), to: MoriaClient.Devices

  ##
  ## Encryption Keys
  ##
  defdelegate list_encryption_keys(client, namespace_id, opts \\ []),
    to: MoriaClient.EncryptionKeys

  defdelegate get_encryption_key(client, namespace_id, key_id),
    to: MoriaClient.EncryptionKeys

  defdelegate create_encryption_key(client, namespace_id, params),
    to: MoriaClient.EncryptionKeys

  defdelegate update_encryption_key(client, namespace_id, key_id, params),
    to: MoriaClient.EncryptionKeys

  defdelegate delete_encryption_key(client, namespace_id, key_id),
    to: MoriaClient.EncryptionKeys

  ##
  ## Messages
  ##

  defdelegate list_messages(client, topic_id, opts \\ []), to: MoriaClient.Messages
  defdelegate stream_messages!(client, topic_id, opts \\ []), to: MoriaClient.Messages
  defdelegate create_messages(client, params), to: MoriaClient.Messages

  ##
  ## Health
  ##

  defdelegate status(client), to: MoriaClient.Status
  defdelegate me(client), to: MoriaClient.Status

  ##
  ## Helpers
  ##
  @doc """
  Returns a new `MoriaClient` instance configured with the given options.

  Options:
  - :base_url - The base URL for the Moria API (default: "http://localhost:4000")
  - :auth - Authentication configuration, e.g., {:bearer, token}
  - :trace - Enable request/response tracing (default: false)
  - :adapter - Tesla adapter configuration (default: {Tesla.Adapter.Mint, timeout: 10_000})
  """
  @spec client(Keyword.t()) :: MoriaClient.t()
  def client(opts \\ []) do
    config = config(opts)
    version = Application.spec(:moria_client, :vsn) |> to_string()
    elixir_version = System.version()

    Tesla.client(
      [
        # base URL for all requests
        {Tesla.Middleware.BaseUrl, Keyword.fetch!(config, :base_url)},
        # default headers
        {Tesla.Middleware.Headers,
         [{"user-agent", "moria_client/#{version} Elixir/#{elixir_version}"}]},
        # encode/decode JSON
        {Tesla.Middleware.JSON, engine: JSON},
        # authentication
        case Keyword.get(config, :auth) do
          {:bearer, token} -> {Tesla.Middleware.BearerAuth, token: token}
          _ -> nil
        end,
        if config[:trace] do
          Tesla.Middleware.Logger
        end,
        Tesla.Middleware.Telemetry
      ]
      |> Enum.reject(&is_nil/1),
      config[:adapter] || {Tesla.Adapter.Mint, timeout: 10_000}
    )
  end

  @doc """
  Returns the merged configuration as used by `client/1`.
  """
  @spec config(Keyword.t()) :: Keyword.t()
  def config(opts) do
    default_config()
    |> Keyword.merge(Application.get_all_env(:moria_client))
    |> Keyword.merge(opts)
  end

  @doc """
  Returns the default configuration for a `MoriaClient`
  before merging with Application config or user overrides.
  """
  @spec default_config() :: Keyword.t()
  def default_config() do
    [
      base_url: "http://localhost:4000",
      trace: false
    ]
  end
end
