defmodule Cashu do
  @moduledoc """
    Main API.
  """

  alias Cashu.Serializer.{JSON, V4}
  alias Cashu.{BDHKE, BlindedMessage, BlindedSignature, ProofV3, ProofV4, TokenV3, TokenV4}
  alias Bitcoinex.Secp256k1.Point, as: SecpPoint

  @doc """
  Parse a Cashu token.
  """
  def parse(<<"cashuA", _::binary>> = msg), do: JSON.deserialize(msg)
  def parse(<<"cashuB", _::binary>> = msg), do: V4.deserialize(msg)
  def parse(msg), do: JSON.deserialize(msg)

  @doc """
  Parse a message to its target struct.
  """
  def parse(msg, target_struct, serializer \\ JSON) do
    serializer.deserialize(msg, target_struct)
  end

  @doc """
  Encode a struct.
  """
  def encode(%TokenV3{} = token), do: JSON.serialize(token)
  def encode(%TokenV4{} = token), do: V4.serialize(token)
  def encode(value), do: JSON.serialize(value)

  @doc """
  Create a Blinded Message, aka an output: a point the mint can sign with the desired amount of ecash at the given keyset.
  """
  def create_output(secret, amount, keyset_id) do
    case BDHKE.blind_point(secret) do
       {:ok, blind_point, _blinding_factor} ->
         b_prime = SecpPoint.serialize_public_key(blind_point)
         BlindedMessage.new(amount, b_prime, keyset_id)
       {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Sign a hex-encoded, user-provided point, aka an output.
  The mint does this traditionally, returning a blinded point C': the ecash token.
  """
  def sign_output(output, amount, privkey) when is_binary(output) do
    case SecpPoint.parse_public_key(output) do
      {:ok, blinded_msg} -> BlindedSignature.new(blinded_msg, amount, privkey)
      {:error, _} = err -> err
    end
  end

  @doc """
  Create a Proof from a secret, a blinded point, and the mint pubkey.
  Provide the amount and keyset_id associated with them.
  """
  def create_proof(c, secret, mint_pubkey, amount, keyset_id) do
    ProofV4.new(c, secret, mint_pubkey, amount, keyset_id)
  end

  def create_proof_v3(c, secret, mint_pubkey, amount, keyset_id) do
    ProofV3.new(c, secret, mint_pubkey, amount, keyset_id)
  end
end
