defmodule MoriaClient.Errors.InternalServerError do
  @type t :: %__MODULE__{env: Tesla.Env.t()}

  defstruct [:env]

  def from_env!(%{status: 500} = env) do
    %__MODULE__{env: env}
  end
end
