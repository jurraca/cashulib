defmodule Cashu.BlindedMessage do
  @moduledoc """
  NUT-00: BlindedMessage
  An encrypted ("blinded") secret and an amount is sent from Alice to Bob for minting tokens or for swapping tokens. A BlindedMessage is also called an output.
  """
  alias Cashu.{BDHKE, Validator}
  alias Bitcoinex.Secp256k1.Point

  defstruct id: nil, amount: 0, b_prime: nil, blinding_factor: nil, secret: nil

  @type t :: %{
          id: String.t(),
          amount: pos_integer(),
          b_prime: binary(),
          blinding_factor: pos_integer(),
          secret: binary()
        }

  def new(), do: %__MODULE__{}
  def new(params) when is_list(params), do: struct!(__MODULE__, params)
  def new(params) when is_map(params), do: Map.to_list(params) |> new()

  def new(amount, secret_message, blinding_factor_hex, keyset_id)
      when is_integer(amount) and is_binary(secret_message) and is_binary(blinding_factor_hex) do
    case BDHKE.blind_point(secret_message, blinding_factor_hex) do
      {:ok, blind_point, blinding_factor} ->
        hex_point = Point.serialize_public_key(blind_point)

        new(%{
          amount: amount,
          id: keyset_id,
          b_prime: hex_point,
          blinding_factor: blinding_factor,
          secret: secret_message
        })

      {:error, _reason} ->
        {:error, "Blind point error"}
    end
  end

  def new(_, _, _, _), do: {:error, :invalid_params}

  def validate(%__MODULE__{amount: amount, id: id, b_prime: b_} = bm) do
    with {:ok, _} <- Validator.validate_amount(amount),
         {:ok, _} <- Validator.validate_id(id),
         {:ok, _} <- Validator.validate_b_(b_) do
      {:ok, bm}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_bm_list(list), do: Validator.validate_list(list, &validate/1)
end

defimpl Jason.Encoder, for: Cashu.BlindedMessage do
  def encode(struct, opts) do
    Jason.Encode.keyword(
      [
        amount: struct.amount,
        id: struct.id,
        B_: struct.b_prime
      ],
      opts
    )
  end
end
