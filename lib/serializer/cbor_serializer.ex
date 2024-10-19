defmodule Cashu.Serializer.V4 do
  @moduledoc """
    Serializes v4 tokens with CBOR.
  """

  @v4_prefix "cashuB"
  @behaviour Cashu.Serializer

  alias Cashu.TokenV4, as: Token

  @impl true
  def serialize(%Token{} = token) do
    case token
         |> format_v4()
         |> Jason.encode() do
      {:ok, json_str} -> {:ok, format_cbor_output(json_str)}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def deserialize(<<"cashuB", token::binary>>) do
    case Base.url_decode64(token, padding: false) do
      {:ok, json_str} -> decode_cbor(json_str)
      :error -> {:error, "could not decode token from binary: #{token}"}
    end
  end

  defp format_v4(token) do
    %{
      m: token.mint,
      u: token.unit,
      d: token.memo,
      t: format_v4_proofs(token.token)
    }
  end

  defp format_v4_proofs(proofs) when is_list(proofs) do
    Enum.map(proofs, fn proof ->
      %{
        i: proof.keyset_id,
        p: %{a: proof.amount, s: proof.secret, c: proof.signature, w: proof.witness}
      }
    end)
  end

  defp format_cbor_output(data) do
    b64_str = data |> CBOR.encode() |> Base.url_encode64()
    @v4_prefix <> b64_str
  end

  defp decode_cbor(str) do
    case CBOR.decode(str) do
      {:ok, bin, ""} -> Jason.decode(bin)
      {:error, reason} -> {:error, reason}
    end
  end
end
