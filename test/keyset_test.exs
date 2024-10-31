defmodule KeysetTest do
  use ExUnit.Case

  alias Cashu.{BDHKE, Keyset}
  alias Bitcoinex.Secp256k1.{Point, PrivateKey}

  setup do
    units = [1, 2, 4, 8] |> Enum.map(&Integer.to_string/1)
    keys = Enum.reduce(units, %{}, fn unit, acc ->
        {:ok, privkey} = BDHKE.random_number() |> PrivateKey.new()
        pubkey = privkey |> PrivateKey.to_point() |> Point.serialize_public_key()
        Map.put(acc, unit, pubkey)
    end)
    {:ok, %{keys: keys}}
  end

  test "generate a keyset ID from a set of keys", %{keys: keys} do
    id = Keyset.derive_keyset_id(keys)
    assert Keyset.valid_id?(%Keyset{id: id, unit: "sat", keys: keys})
  end

  describe "NUT-01 test vectors" do
    test "key1 is missing a byte" do
       keyset = %{
          "1" => "03a40f20667ed53513075dc51e715ff2046cad64eb68960632269ba7f0210e38",
          "2" => "03fd4ce5a16b65576145949e6f99f445f8249fee17c606b688b504a849cdc452de",
          "4" =>  "02648eccfa4c026960966276fa5a4cae46ce0fd432211a4f449bf84f13aa5f8303",
          "8" => "02fdfd6796bfeac490cbee12f778f867f0a2c68f6508d17c649759ea0dc3547528"
        }
       result = for {_k, v} <- keyset do
          Keyset.valid_key?(v)
       end
       assert [false, true, true, true  ] == result
    end

    test "key is uncompressed" do
      keyset = %{
        "1" => "03a40f20667ed53513075dc51e715ff2046cad64eb68960632269ba7f0210e38bc",
        "2" => "04fd4ce5a16b65576145949e6f99f445f8249fee17c606b688b504a849cdc452de3625246cb2c27dac965cb7200a5986467eee92eb7d496bbf1453b074e223e481",
        "4" => "02648eccfa4c026960966276fa5a4cae46ce0fd432211a4f449bf84f13aa5f8303",
        "8" => "02fdfd6796bfeac490cbee12f778f867f0a2c68f6508d17c649759ea0dc3547528"
      }

       result = for {_k, v} <- keyset do
          Keyset.valid_key?(v)
       end
       assert [true, false, true, true  ] == result
    end
  end
end

