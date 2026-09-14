defmodule MoriaClient.Devices.DeviceTopicSource do
  use MoriaClient.Schema

  @type t :: %__MODULE__{
          topic_source_id: String.t(),
          discovery_method: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key false
  embedded_schema do
    field :topic_source_id, :string
    field :discovery_method, :string
    field :inserted_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def changeset(device_topic_source \\ %__MODULE__{}, attrs) do
    Ecto.Changeset.cast(device_topic_source, attrs, __schema__(:fields))
  end
end
