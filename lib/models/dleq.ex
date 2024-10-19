defmodule Cashu.DLEQ do

  @derive Jason.Encoder
  defstruct challenge: nil, response: nil, blinding_factor: nil

  @type t :: %{
    challenge: binary(),
    response: binary(),
    blinding_factor: binary()
  }

  def new, do: %__MODULE__{}
end
