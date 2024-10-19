defmodule Cashu.Mint do
  @moduledoc """
  NUT-04: mint quotes and requests. Minting means "exchanging an asset for ecash".
  """
  defmodule QuoteRequest do
    @moduledoc """
    Mint Quote Request: the wallet requests an invoice to pay in order to receive ecash.
    The unit specifies the unit that denominates the amount.
    The path of the request will indicate the invoice method, for example, bolt11 for Lightning Bolt11 invoices.
    """

    @derive Jason.Encoder
    defstruct amount: 0, unit: nil

    @type t :: %{
            amount: pos_integer(),
            unit: String.t()
          }

    def new, do: %__MODULE__{}

    @spec new(pos_integer(), String.t()) :: {:ok, t()} | {:error, binary()}
    def new(amount, unit \\ "sat") when is_integer(amount) do
      case amount > 0 do
         true -> {:ok, %__MODULE__{amount: amount, unit: unit}}
         false -> {:error, "Amount must be a positive integer"}
      end
    end
  end

  defmodule QuoteResponse do
    @moduledoc """
    The mint responds with a `QuoteResponse`. The `quote` field is a unique ID used for internal payment state. It MUST NOT be derivable from the payment `request`.
    For a Lightning BOLT11 payment, the request will be a BOLT11 invoice.
    """
    @derive Jason.Encoder
    defstruct quote: "", request: "", paid: false, expiry: 0

    @type t :: %{
            quote: String.t(),
            request: String.t(),
            paid: boolean(),
            expiry: pos_integer()
          }

    def new, do: %__MODULE__{}

    def new(quote_id, request, paid, expiry) do
      %__MODULE__{
        quote: quote_id,
        request: request,
        paid: paid,
        expiry: expiry
      }
    end
  end

  defmodule Request do
    @moduledoc """
    Once the wallet has paid the invoice in the `request` field of `QuoteResponse`, it provides an array of `BlindedMessage` which sum to the amount requested in the quote, along with the `quote` ID.
    """
    alias Cashu.BlindedMessage

    @derive Jason.Encoder
    defstruct quote: "", outputs: []

    @type t :: %{
            quote: String.t(),
            outputs: [BlindedMessage.t()]
          }

    def new, do: %__MODULE__{}

    def new(quote_id, outputs) when is_list(outputs) do
      %__MODULE__{
        quote: quote_id,
        outputs: outputs
      }
    end
  end

  defmodule Response do
    @moduledoc """
    In response to a `Mint.Request`, the mint signs each `BlindedMessage` provided, and returns an array of `BlindedSignature`.
    Upon receiving these, the wallet will unblind these signatures, and store those as `Proofs` in their database.
    """
    alias Cashu.BlindedSignature

    @derive Jason.Encoder
    defstruct signatures: []

    @type t :: %{signatures: [BlindedSignature.t()]}

    def new, do: %__MODULE__{}

    def new(signatures) when is_list(signatures) do
      %__MODULE__{
        signatures: signatures
      }
    end
  end
end
