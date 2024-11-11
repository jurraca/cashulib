defmodule Cashu.BDHKETest do
  alias Bitcoinex.Secp256k1.PrivateKey
  alias Bitcoinex.Secp256k1.Point
  alias Cashu.BDHKE
  use ExUnit.Case

  describe "generate_proof/3" do
    test "test 01" do
      c_ = "02f808cc3ba75657fa591a43fce914297eb993fe7cea34e8b5438c5024d8ad4069"
      r = "b41576276b780b9467a634a02d21e14d0ecec280be82b14444764177030c6d81"

      {:ok, mint_privkey} =
        "c792bf68fa82a5002348fa0e58e4dd201f5910231f4e08271924699c9268177a"
        |> Integer.parse(16)
        |> elem(0)
        |> PrivateKey.new()

      {:ok, c} = BDHKE.generate_proof(c_, r, PrivateKey.to_point(mint_privkey))

      assert Point.serialize_public_key(c) ==
               "03d2e8a90ebe71819a9e76ce535de7a622ba302c639675608b539dfac2f60afb96"
    end
  end
end
