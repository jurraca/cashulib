defmodule Cashu.BlindedMessage do
  @moduledoc """
  NUT-00: BlindedMessage
  An encrypted ("blinded") secret and an amount is sent from Alice to Bob for minting tokens or for swapping tokens. A BlindedMessage is also called an output.
  """
  alias Cashu.{BDHKE, Validator}
  alias Bitcoinex.Secp256k1.Point

  @derive Jason.Encoder
  defstruct id: nil, amount: 0, b_prime: nil

  @type t :: %{
    id: String.t(),
    amount: pos_integer(),
    b_prime: binary()
  }

  def new(), do: %__MODULE__{}
  def new(params) when is_list(params), do: struct!(__MODULE__, params)
  def new(params) when is_map(params), do: Map.to_list(params) |> new()

  def new(amount, secret_message, keyset_id)
      when is_integer(amount) and is_binary(secret_message) do
    case BDHKE.blind_point(secret_message) do
      {:ok, blind_point, _blinding_factor} ->
        hex_point = Point.serialize_public_key(blind_point)
        new(%{amount: amount, id: keyset_id, b_: hex_point})

      {:error, _reason} ->
        {:error, "Blind point error"}
    end
  end

  def new(_, _, _), do: {:error, :invalid_params}

  def validate(%__MODULE__{amount: amount, id: id, b_prime: b_} = bm) do
    with {:ok , _} <- Validator.validate_amount(amount),
         {:ok, _}<- Validator.validate_id(id),
         {:ok, _} <- Validator.validate_b_(b_) do
      {:ok, bm}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_bm_list(list), do: Validator.validate_list(list, &validate/1)
end
