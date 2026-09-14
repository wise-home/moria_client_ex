defmodule MoriaClient.Devices.DevicesPage do
  use MoriaClient.Schema

  @type t :: %__MODULE__{
          page: MoriaClient.Common.PageInfo.t(),
          devices: [MoriaClient.Devices.Device.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_one :page, MoriaClient.Common.PageInfo
    embeds_many :devices, MoriaClient.Devices.Device
  end

  def changeset(page \\ %__MODULE__{}, attrs) do
    page
    |> Ecto.Changeset.cast(attrs, [])
    |> Ecto.Changeset.cast_embed(:page)
    |> Ecto.Changeset.cast_embed(:devices)
  end
end
