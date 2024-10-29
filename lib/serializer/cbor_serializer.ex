defmodule Cashu.Serializer.V4 do
  @moduledoc """
    Serializes v4 tokens with CBOR.
  """

  @v4_prefix "cashuB"
  @behaviour Cashu.Serializer

  alias Cashu.TokenV4, as: Token

  @impl true
  def serialize(%Token{} = token, include_witness \\ false) do
    {
      :ok,
      token
      |> format_v4(include_witness)
      |> format_cbor_output()
    }
  end

  @impl true
  def deserialize(<<"cashuB", token::binary>>) do
    case Base.url_decode64(token, padding: false) do
      {:ok, json_str} -> decode_cbor(json_str)
      :error -> {:error, "could not decode token from binary: #{token}"}
    end
  end

  defp format_v4(token, include_witness) do
    %{
      m: token.mint,
      u: token.unit,
      d: token.memo,
      t: format_v4_proofs(token.token, include_witness)
    }
  end

  defp format_v4_proofs(proofs, include_witness) when is_list(proofs) do
    by_keyset = Enum.group_by(proofs, & &1.keyset_id)

    Enum.map(by_keyset, fn {keyset_id, proofs} ->
      %{
        i: keyset_id,
        p:
          Enum.map(proofs, fn proof ->
            # TODO: add witness if include_witness is true
            %{a: proof.amount, s: proof.secret, c: proof.signature}
          end)
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
