defmodule Cashu.Mint.Contact do
    @derive Jason.Encoder
    defstruct method: "", info: ""

    def new, do: %__MODULE__{}
    def new(method, info), do: %__MODULE__{method: method, info: info}
end
