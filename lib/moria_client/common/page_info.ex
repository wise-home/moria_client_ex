defmodule MoriaClient.Common.PageInfo do
  use MoriaClient.Schema

  @type t :: %__MODULE__{
          has_next_page: boolean() | nil,
          has_previous_page: boolean() | nil,
          start_cursor: String.t() | nil,
          end_cursor: String.t() | nil,
          total_count: integer() | nil
        }

  @primary_key false
  embedded_schema do
    field :has_next_page, :boolean
    field :has_previous_page, :boolean
    field :start_cursor, :string
    field :end_cursor, :string
    field :total_count, :integer
  end

  def changeset(page_info \\ %__MODULE__{}, attrs) do
    page_info
    |> Ecto.Changeset.cast(attrs, [
      :has_next_page,
      :has_previous_page,
      :start_cursor,
      :end_cursor,
      :total_count
    ])
  end
end
