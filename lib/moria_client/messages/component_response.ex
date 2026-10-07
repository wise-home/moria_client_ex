defmodule MoriaClient.Messages.ComponentResponse do
  use MoriaClient.Schema

  @primary_key false
  embedded_schema do
    # a map of request names, and their corresponding results or errors.

    # The schema for a result depends on what operation was performed.
    # This can be found in the result's `op` field.
    field :results, :map, default: %{}

    # The schema for an error contains a message and a code field.
    field :errors, :map, default: %{}
  end

  def changeset(namespace \\ %__MODULE__{}, attrs) do
    namespace
    |> Ecto.Changeset.cast(attrs, __schema__(:fields))
    |> Ecto.Changeset.update_change(:errors, &cast_errors/1)
    |> Ecto.Changeset.validate_required([:results, :errors])
  end

  defp cast_errors(errors) do
    Map.new(errors, fn {key, error_attrs_list} ->
      error_list =
        Enum.map(error_attrs_list, fn attrs ->
          attrs
          |> MoriaClient.Messages.ComponentResponseError.changeset()
          |> Ecto.Changeset.apply_changes()
        end)

      {key, error_list}
    end)
  end
end
