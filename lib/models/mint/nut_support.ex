defmodule Cashu.Mint.NutSupport do
   defstruct nut_int: 0, supported: true, disabled: false, methods: []

   def new, do: %__MODULE__{}
   def new(opts) do
    supported = Keyword.get(opts, :supported)
    disabled = Keyword.get(opts, :disabled)
    if supported == disabled do
        {:error, "A NUT cannot both be supported and disabled, or both nil. Choose one."}
    else
     %__MODULE__{
        nut_int: Keyword.get(opts, :nut_int),
        supported: supported,
        disabled: disabled,
        methods: Keyword.get(opts, :methods)
     }
     end
   end
end
