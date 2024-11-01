defmodule Cashu.Keyset do
  @moduledoc """
  NUT-01: public keys which the mint will sign new outputs with.
  The `get_keys_response/1` function should be used to return the *active* keysets
  via the `/v1/keys` endpoint to the user.
  """
  alias Cashu.{Error, Validator}

  @keyset_version "00"

  @derive Jason.Encoder
  defstruct [:id, :active, :unit, :keys]

  @type mint_pubkeys() :: %{
          required(String.t()) => String.t()
        }

  @type t :: %__MODULE__{
          id: String.t(),
          active: boolean(),
          unit: String.t(),
          input_fee_ppk: pos_integer(),
          keys: mint_pubkeys()
        }

  def new(), do: %__MODULE__{}

  def new(params), do: struct!(%__MODULE__{}, params)

  def new(keys, unit, active) when is_map(keys) and is_binary(unit) do
    with id <- derive_keyset_id(keys) do
      %__MODULE__{
        id: id,
        unit: unit,
        active: active,
        keys: keys
      }
    end
  end

  def new(_, _), do: {:error, :invalid_keyset_or_unit}

  def new_key(pubkey, denomination) when is_integer(denomination) do
    Map.put(%{}, Integer.to_string(denomination), pubkey)
  end

  def update_keys(nil, new_key) when is_map(new_key), do: new_key

  def update_keys(keys, new_key) when is_map(new_key) do
    Map.merge(keys, new_key)
  end

  def add_key_to_keyset(%__MODULE__{keys: keys} = keyset, key) do
    new_keys = update_keys(keys, key)
    new_id = derive_keyset_id(new_keys)
    %{keyset | keys: new_keys, id: new_id}
  end

  def remove_key(%{keys: keys}, keyset_id) do
    {denomination, _id} = keys |> Enum.find(fn {_k, v} -> v == keyset_id end)
    Map.drop(keys, [denomination])
  end

  def derive_keyset_id(keys) when is_map(keys) do
    pubkey_concat =
      keys
      |> sort_keys()
      |> Enum.map(fn {_k, v} -> Base.decode16!(v, case: :lower) end)
      |> Enum.join()

    id =
      :crypto.hash(:sha256, pubkey_concat)
      |> Base.encode16(case: :lower)
      |> String.slice(0..13)

    @keyset_version <> id
  end

  def valid_id?(%__MODULE__{id: id, keys: keys}) do
    id == derive_keyset_id(keys)
  end

  @doc """
  Check that the denominations and pubkeys for a keys map are correctly formatted.
  """
  def valid_keys?(keys) do
    keys
    |> Enum.map(fn {denomination, pubkey} ->
     valid_denom?(denomination) && valid_key?(pubkey)
    end)
    |> Enum.all?
  end

  def valid_key?(key) when is_binary(key) do
    case Validator.validate_key_len(key) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  def valid_key?(_), do: false

  def valid_denom?(denomination) when is_atom(denomination) do
    Atom.to_string(denomination) |> valid_denom?()
  end

  def valid_denom?(denomination) when is_binary(denomination) do
      try do
        String.to_integer(denomination) && true
      rescue
        ArgumentError -> false
      end
  end

  def validate(%{id: id, unit: unit, active: active} = keyset) do
    with true <- is_boolean(active),
         {:ok, _} <- Validator.validate_unit(unit),
         {:ok, _} <- Validator.validate_keyset_id(id) do
      {:ok, keyset}
    else
      {:error, reason} -> Error.new(reason)
    end
  end

  defp sort_keys(keys) do
    keys
    |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
    |> Enum.sort(&(elem(&1, 0)) < elem(&2, 0))
  end
end
