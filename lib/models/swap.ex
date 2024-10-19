defmodule Cashu.Swap do
  defmodule Request do
    @moduledoc """
    Request swap tokens
    """
   alias Cashu.{BlindedMessage, ProofV3, ProofV4}
   @derive Jason.Encoder

   defstruct inputs: [], outputs: []

    @type t :: %{
            inputs: [ProofV3.t()] | [ProofV4.t()],
            outputs: [BlindedMessage.t()]
          }

    def new(inputs, outputs) when is_list(inputs) and is_list(outputs) do
      %__MODULE__{
        inputs: inputs,
        outputs: outputs
      }
    end

    def validate(%{inputs: inputs, outputs: outputs} = swap_req) do
      with {:error, []} <- ProofV3.validate_proof_list(inputs),
           {:error, []} <- BlindedMessage.validate_bm_list(outputs) do
        {:ok, swap_req}
      end
    end
  end

  defmodule Response do
    @moduledoc """
    Swap Response: mint responds with blind signatures on the previously provided tokens.
    """
    alias Cashu.BlindedSignature

    @derive Jason.Encoder
    defstruct signatures: []

    @type t :: %{
            signatures: [BlindedSignature.t()]
          }

    def new(signatures) do
      %__MODULE__{
        signatures: signatures
      }
    end

    def validate(%{signatures: sigs}) do
      BlindedSignature.validate_sig_list(sigs)
    end
  end
end
