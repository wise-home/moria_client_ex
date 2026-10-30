defmodule MoriaClient.Errors.BadRequest do
  alias MoriaClient.Common.FieldError

  @type t :: %__MODULE__{
          details: [FieldError.t()],
          message: String.t() | nil
        }

  defstruct [:details, :message]

  def from_env!(%{status: 400, body: %{"error" => error}}) do
    details =
      Enum.flat_map(error["details"] || [], fn {field, reasons} ->
        Enum.map(reasons, &FieldError.new(field, &1))
      end)

    message = error["message"]

    %__MODULE__{
      details: details,
      message: message
    }
  end
end
