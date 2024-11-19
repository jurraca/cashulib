defmodule Cashu do
  @moduledoc """
    Main API.
  """

  alias Cashu.Serializer.{JSON, V4}
  alias Cashu.{BlindedMessage, BlindedSignature, ProofV3, ProofV4, TokenV3, TokenV4}
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
  def create_output(secret, amount, blinding_factor_hex, keyset_id) do
    BlindedMessage.new(amount, secret, blinding_factor_hex, keyset_id)
  end

  @doc """
  Sign a hex-encoded, user-provided point, aka an output.
  The mint does this traditionally, returning a blinded point C': the ecash token.
  """
  def sign_output(output, amount, keyset_id, privkey) when is_binary(output) do
    case SecpPoint.parse_public_key(output) do
      {:ok, blinded_msg} -> BlindedSignature.new(blinded_msg, amount, keyset_id, privkey)
      {:error, _} = err -> err
    end
  end

  @doc """
  Create a Proof from a secret, a blinded point, and the mint pubkey.
  Provide the amount and keyset_id associated with them.
  """
  def create_proof(c_, blinding_factor, secret, amount, keyset_id, mint_pubkey)
      when is_binary(mint_pubkey) do
    ProofV4.new(c_, blinding_factor, secret, amount, keyset_id, mint_pubkey)
  end

  def create_proof_v3(c, secret, mint_pubkey, amount, keyset_id) do
    ProofV3.new(c, secret, mint_pubkey, amount, keyset_id)
  end
end
