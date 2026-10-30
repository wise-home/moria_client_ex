defmodule MoriaClient.Errors.Unauthorized do
  @type t :: %__MODULE__{}

  defstruct []

  def from_env!(%{status: 401}) do
    %__MODULE__{}
  end
end
