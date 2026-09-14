defmodule MoriaClient.Devices.Device do
  use MoriaClient.Schema

  @type t :: %__MODULE__{
          namespace_id: String.t(),
          name: String.t() | nil,
          reference: String.t() | nil,
          identification: String.t() | nil,
          description: String.t() | nil,
          metadata: [MoriaClient.Common.Metadata.t()],
          device_topic_sources: [MoriaClient.Devices.DeviceTopicSource.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  embedded_schema do
    field :namespace_id, :string
    field :name, :string
    field :reference, :string
    field :identification, :string
    field :description, :string
    field :inserted_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
    embeds_many :metadata, MoriaClient.Common.Metadata
    embeds_many :device_topic_sources, MoriaClient.Devices.DeviceTopicSource
  end

  def changeset(device \\ %__MODULE__{}, attrs) do
    device
    |> Ecto.Changeset.cast(attrs, __schema__(:fields) -- __schema__(:embeds))
    |> Ecto.Changeset.cast_embed(:metadata)
    |> Ecto.Changeset.cast_embed(:device_topic_sources)
  end
end
