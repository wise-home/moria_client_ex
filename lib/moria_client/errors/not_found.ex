defmodule MoriaClient.Errors.NotFound do
  @type t :: %__MODULE__{}

  defstruct []

  def from_env!(%{status: 404}) do
    %__MODULE__{}
  end
end
