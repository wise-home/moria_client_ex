defmodule MoriaClient.Common.FieldError do
  @type t :: %__MODULE__{field: String.t(), reason: String.t()}

  defstruct [:field, :reason]

  def new(field, reason) do
    %__MODULE__{field: field, reason: reason}
  end
end
