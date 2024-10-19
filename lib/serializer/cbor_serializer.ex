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
      {:ok, output, ""} ->
        new_out = Map.update!(output, "t", &handle_cbor_tags(&1))
        {:ok, new_out}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_cbor_tags(tokens) do
    Enum.map(tokens, fn %{"i" => i, "p" => p} ->
      new_i = maybe_handle_tag(i)

      new_p =
        Enum.map(p, fn proof ->
          Map.update!(proof, "c", &maybe_handle_tag(&1))
        end)

      %{"i" => new_i, "p" => new_p}
    end)
  end

  defp maybe_handle_tag(%CBOR.Tag{} = data), do: data.value
  defp maybe_handle_tag(data), do: data
end
