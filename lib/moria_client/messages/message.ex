defmodule MoriaClient.Messages.Message do
  use MoriaClient.Schema

  @type t :: %__MODULE__{
          inserted_at: DateTime.t(),
          captured_at: DateTime.t(),
          payload_type_id: String.t(),
          payload_size: integer(),
          topic_id: String.t(),
          components: map()
        }

  embedded_schema do
    field :inserted_at, :utc_datetime_usec
    field :captured_at, :utc_datetime_usec
    field :payload_type_id, :string
    field :payload_size, :integer
    field :topic_id, :string

    # deprecated, use response instead
    field :components, :map, default: %{}, virtual: false

    embeds_one :response, MoriaClient.Messages.ComponentResponse
  end

  def changeset(namespace \\ %__MODULE__{}, attrs) do
    namespace
    |> Ecto.Changeset.cast(attrs, __schema__(:fields) -- __schema__(:embeds))
    |> Ecto.Changeset.cast_embed(:response)
  end
end
