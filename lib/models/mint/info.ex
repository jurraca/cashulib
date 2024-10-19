defmodule Cashu.Mint.Info do
  @moduledoc """
  NUT-06: mint info
  """
  defstruct name: "", pubkey: "", version: "", description: nil, description_long: nil, motd: nil, icon_url: nil, time: 0, contact: [], nuts: []

  def new, do: %__MODULE__{}

  def new(name, pubkey, opts \\ []) do
    %__MODULE__{
      name: name,
      pubkey: pubkey,
      version: Keyword.get(opts, :version),
      description: Keyword.get(opts, :description),
      description_long: Keyword.get(opts, :description_long),
      contact: Keyword.get(opts, :contact),
      motd: Keyword.get(opts, :motd),
      nuts: Keyword.get(opts, :nuts)
    }
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.reject(fn {_, v} -> is_nil(v) || (v == []) end)
      |> Map.reject(fn {k, _v} -> k == :__struct__ end)
      |> Map.update!(:nuts, &encode(&1))
      |> Jason.Encode.map(opts)
    end

    def encode(list_nutsupport) when is_list(list_nutsupport) do
        list_nutsupport
        |> Enum.reduce(%{}, fn x, acc ->
          m = format(x)
          Map.merge(acc, m)
        end)
    end

    defp format(struct) do
      {nut, fields} = Map.pop!(struct, :nut_int)
      m = fields
        |> Map.reject(fn {_, v} -> is_nil(v) end)
        |> Map.reject(fn {k, _} -> k == :__struct__ end)
      %{"#{nut}" => m}
    end
  end
end
