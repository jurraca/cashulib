defmodule Cashu.BlindedSignature do
  @moduledoc """
  NUT-00: BlindedSignature
  A BlindedSignature is sent from Bob to Alice after minting tokens or after swapping tokens. A BlindedSignature is also called a promise.
  """
  alias Cashu.{BDHKE, Validator}
  alias Bitcoinex.Secp256k1.Point

  @derive Jason.Encoder
  defstruct id: nil, amount: 0, c_prime: nil

  @type t :: %{
    id: String.t(),
    amount: pos_integer(),
    c_prime: binary()
  }

  def new(), do: %__MODULE__{}
  def new(params) when is_list(params), do: struct!(__MODULE__, params)
  def new(params) when is_map(params), do: Map.to_list(params) |> new()

  def new(blinded_message, amount, keyset_id, mint_privkey) do
    case BDHKE.sign_blinded_point(blinded_message, mint_privkey) do
      {:ok, commitment_point, _e, _s} ->
        hex_c_ = Point.serialize_public_key(commitment_point)
        new(%{amount: amount, id: keyset_id, c_prime: hex_c_})

      {:error, reason} ->
        {:error, reason}
    end
  end

  def validate(%__MODULE__{amount: amount, id: id, c_prime: c_} = sig) do
    with {:ok, _} <- Validator.validate_amount(amount),
         {:ok, _} <- Validator.validate_id(id),
         {:ok, _} <- Validator.validate_c_(c_) do
      {:ok, sig}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_sig_list(list), do: Validator.validate_list(list, &validate/1)
end
