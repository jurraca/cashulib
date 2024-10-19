defmodule Cashu do
  @moduledoc """
    Main API.
  """

  alias Cashu.Serializer.{JSON, V4}
  alias Cashu.{TokenV3, TokenV4}

  def parse(<<"cashuA", _::binary>> = msg), do: JSON.deserialize(msg)
  def parse(<<"cashuB", _::binary>> = msg), do: V4.deserialize(msg)
  def parse(msg), do: JSON.deserialize(msg)

  def parse(msg, target_struct, serializer \\ JSON) do
    serializer.deserialize(msg, target_struct)
  end

  def encode(%TokenV3{} = token), do: JSON.serialize(token)
  def encode(%TokenV4{} = token), do: V4.serialize(token)
  def encode(value), do: JSON.serialize(value)
end
