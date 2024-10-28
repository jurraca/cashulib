defmodule BDHKETest do
  use ExUnit.Case

  alias Bitcoinex.Secp256k1.Point
  alias Cashu.BDHKE

  # These test vectors can be found here: https://github.com/cashubtc/nuts/blob/main/tests/00-tests.md

  describe "hash_to_curve function tests" do
    test "0x00" do
      {:ok, secret_msg} =
        "0000000000000000000000000000000000000000000000000000000000000000" |> Base.decode16()

      {:ok, %Point{} = point} = BDHKE.hash_to_curve(secret_msg)

      assert Point.serialize_public_key(point) ==
               "024cce997d3b518f739663b757deaec95bcd9473c30a14ac2fd04023a739d1a725"
    end

    test "0x01" do
      {:ok, secret_msg} =
        "0000000000000000000000000000000000000000000000000000000000000001" |> Base.decode16()

      {:ok, %Point{} = point} = BDHKE.hash_to_curve(secret_msg)

      assert Point.serialize_public_key(point) ==
               "022e7158e11c9506f1aa4248bf531298daa7febd6194f003edcd9b93ade6253acf"
    end

    test "0x02" do
      {:ok, secret_msg} =
        "0000000000000000000000000000000000000000000000000000000000000002" |> Base.decode16()

      {:ok, %Point{} = point} = BDHKE.hash_to_curve(secret_msg)

      assert Point.serialize_public_key(point) ==
               "026cdbe15362df59cd1dd3c9c11de8aedac2106eca69236ecd9fbe117af897be4f"
    end
  end

  describe "Blinded messages" do
    test "test case 01" do
      x = "d341ee4871f1f889041e63cf0d3823c713eea6aff01e80f1719f08f9e5be98f6"
      r = "99fce58439fc37412ab3468b73db0569322588f62fb3a49182d67e23d877824a"

      assert {:ok, point, _} = BDHKE.blind_point(x, r)

      assert Point.serialize_public_key(point) ==
               "033b1a9737a40cc3fd9b6af4b723632b76a67a36782596304612a6c2bfb5197e6d"
    end

    test "test case 02" do
      x = "f1aaf16c2239746f369572c0784d9dd3d032d952c2d992175873fb58fae31a60"
      r = "f78476ea7cc9ade20f9e05e58a804cf19533f03ea805ece5fee88c8e2874ba50"

      assert {:ok, point, _} = BDHKE.blind_point(x, r)

      assert Point.serialize_public_key(point) ==
               "029bdf2d716ee366eddf599ba252786c1033f47e230248a4612a5670ab931f1763"
    end
  end

  describe "Blinded signatures" do
    test "test case 01" do
      mint_priv_key = "0000000000000000000000000000000000000000000000000000000000000001"
      b_ = "02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2"

      assert {:ok, c_, _, _} = BDHKE.sign_blinded_point(b_, mint_priv_key)

      assert Point.serialize_public_key(c_) ==
               "02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2"
    end

    test "test case 02" do
      mint_priv_key = "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f"
      b_ = "02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2"

      assert {:ok, c_, _, _} = BDHKE.sign_blinded_point(b_, mint_priv_key)

      assert Point.serialize_public_key(c_) ==
               "0398bc70ce8184d27ba89834d19f5199c84443c31131e48d3c1214db24247d005d"
    end
  end
end
