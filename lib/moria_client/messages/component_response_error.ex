defmodule MoriaClient.Messages.ComponentResponseError do
  use MoriaClient.Schema

  @primary_key false
  embedded_schema do
    field :message, :string
    field :code, :string
    field :component_request, :map, default: %{}
  end

  def changeset(error \\ %__MODULE__{}, attrs) do
    Ecto.Changeset.cast(error, attrs, __schema__(:fields))
  end
end
