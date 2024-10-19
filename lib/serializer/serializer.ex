defmodule Cashu.Serializer do
  # interfaces that each module should implement
  @callback serialize(map()) :: {:ok, binary()} | {:error, binary()}
  @callback deserialize(binary()) :: {:ok, map()} | {:error, binary()}
end
