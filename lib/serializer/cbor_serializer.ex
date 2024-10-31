defmodule Cashu.Serializer.V4 do
  @moduledoc """
    Serializes v4 tokens with CBOR.
  """

  @v4_prefix "cashuB"
  @behaviour Cashu.Serializer

  alias Cashu.ProofV4
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
        i: %CBOR.Tag{tag: :bytes, value: :binary.decode_hex(keyset_id)},
        p:
          Enum.map(proofs, fn proof ->
            # TODO: add witness if include_witness is true
            %{
              a: proof.amount,
              s: proof.secret,
              c: %CBOR.Tag{tag: :bytes, value: :binary.decode_hex(proof.signature)}
            }
          end)
      }
    end)
  end

  defp format_cbor_output(data) do
    b64_str = data |> CBOR.encode() |> Base.url_encode64()
    @v4_prefix <> b64_str
  end

  @impl true
  def deserialize(<<"cashuB", token::binary>>) do
    case Base.url_decode64(token, padding: false) do
      {:ok, cbor_bytes} -> decode_cbor(cbor_bytes)
      :error -> {:error, "could not decode token from binary: #{token}"}
    end
  end

  defp decode_cbor(str) do
    case CBOR.decode(str) do
      {:ok, output, ""} ->
        {:ok,
         output
         |> Map.update!("t", &handle_cbor_tags(&1))
         |> to_v4_token()}

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

  defp to_v4_token(map) do
    %Token{
      mint: map["m"],
      unit: map["u"],
      memo: map["d"],
      token: parse_tokens(map["t"])
    }
  end

  defp parse_tokens(tokens) do
    Enum.flat_map(tokens, &parse_proofs(&1))
  end

  defp parse_proofs(%{"i" => i, "p" => p}) do
    Enum.map(p, &(&1 |> Map.put("i", i) |> ProofV4.from_cbor_serialized_map()))
  end
end
