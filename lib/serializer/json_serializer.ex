defmodule Cashu.Serializer.JSON do
  @moduledoc """
  A serializer that uses the JSON format and Jason library.
  """
  alias Cashu.TokenV3

  @behaviour Cashu.Serializer

  @doc """
  Serialize given term to JSON binary data.
  """
  @impl true
  def serialize(%TokenV3{} = token) do
    case Jason.encode(token) do
      {:ok, encoded} ->
        serialized = Base.url_encode64(encoded, padding: false)
        {:ok, "cashuA" <> serialized}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def serialize(term), do: Jason.encode(term)

  @doc """
  Deserialize given JSON binary data to the expected type.
  """
  @impl true
  def deserialize(<<"cashu", _version::binary-size(1), token::binary>>) do
    # if(version != "A", do: Logger.info("Got cashu token version #{version}"))
    case Base.url_decode64(token, padding: false) do
      {:ok, json_str} -> {:ok, deserialize(json_str, %TokenV3{})}
      :error -> {:error, "could not decode token from binary #{token}"}
    end
  end

  def deserialize(msg) when is_binary(msg), do: Jason.decode(msg, keys: :atoms)
  def deserialize(_msg), do: {:error, "Cannot deserialize message: not a binary"}

  def deserialize(binary, target_struct) do
    case deserialize(binary) do
      {:ok, json} -> to_struct(json, target_struct)
      {:error, _} = err -> err
    end
  end

  defp to_struct(data, nil), do: data
  defp to_struct(data, struct), do: struct(struct, data)
end
