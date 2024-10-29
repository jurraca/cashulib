defmodule BDHKETest do
  use ExUnit.Case

  alias Bitcoinex.Secp256k1.Point
  alias Cashu.BDHKE
  alias Cashu.ProofV3
  alias Cashu.ProofV4
  alias Cashu.TokenV3
  alias Cashu.TokenV4

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

  describe "token V3" do
    test "serializes into base64_urlsafe string" do
      token = %TokenV3{
        token: [
          %{
            mint: "https://8333.space:3338",
            proofs: [
              %ProofV3{
                amount: 2,
                id: "009a1f293253e41e",
                secret: "407915bc212be61a77e3e6d2aeb4c727980bda51cd06a6afc29e2861768a7837",
                c: "02bc9097997d81afb2cc7346b5e4345a9346bd2a506eb7958598a72f0cf85163ea"
              },
              %ProofV3{
                amount: 8,
                id: "009a1f293253e41e",
                secret: "fe15109314e61d7756b0f8ee0f23a624acaa3f4e042f61433c728c7057b931be",
                c: "029e8e5050b890a7d6c0968db16bc1d5d5fa040ea1de284f6ec69d61299f671059"
              }
            ]
          }
        ],
        unit: "sat",
        memo: "Thank you."
      }

      {:ok, serialized} = Cashu.Serializer.JSON.serialize(token)

      assert serialized ==
               "cashuAeyJ0b2tlbiI6W3sibWludCI6Imh0dHBzOi8vODMzMy5zcGFjZTozMzM4IiwicHJvb2ZzIjpbeyJhbW91bnQiOjIsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6IjQwNzkxNWJjMjEyYmU2MWE3N2UzZTZkMmFlYjRjNzI3OTgwYmRhNTFjZDA2YTZhZmMyOWUyODYxNzY4YTc4MzciLCJDIjoiMDJiYzkwOTc5OTdkODFhZmIyY2M3MzQ2YjVlNDM0NWE5MzQ2YmQyYTUwNmViNzk1ODU5OGE3MmYwY2Y4NTE2M2VhIn0seyJhbW91bnQiOjgsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6ImZlMTUxMDkzMTRlNjFkNzc1NmIwZjhlZTBmMjNhNjI0YWNhYTNmNGUwNDJmNjE0MzNjNzI4YzcwNTdiOTMxYmUiLCJDIjoiMDI5ZThlNTA1MGI4OTBhN2Q2YzA5NjhkYjE2YmMxZDVkNWZhMDQwZWExZGUyODRmNmVjNjlkNjEyOTlmNjcxMDU5In1dfV0sInVuaXQiOiJzYXQiLCJtZW1vIjoiVGhhbmsgeW91LiJ9"
    end

    test "successful deserialization" do
      assert {:ok, _} =
               Cashu.Serializer.JSON.deserialize(
                 "cashuAeyJ0b2tlbiI6W3sibWludCI6Imh0dHBzOi8vODMzMy5zcGFjZTozMzM4IiwicHJvb2ZzIjpbeyJhbW91bnQiOjIsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6IjQwNzkxNWJjMjEyYmU2MWE3N2UzZTZkMmFlYjRjNzI3OTgwYmRhNTFjZDA2YTZhZmMyOWUyODYxNzY4YTc4MzciLCJDIjoiMDJiYzkwOTc5OTdkODFhZmIyY2M3MzQ2YjVlNDM0NWE5MzQ2YmQyYTUwNmViNzk1ODU5OGE3MmYwY2Y4NTE2M2VhIn0seyJhbW91bnQiOjgsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6ImZlMTUxMDkzMTRlNjFkNzc1NmIwZjhlZTBmMjNhNjI0YWNhYTNmNGUwNDJmNjE0MzNjNzI4YzcwNTdiOTMxYmUiLCJDIjoiMDI5ZThlNTA1MGI4OTBhN2Q2YzA5NjhkYjE2YmMxZDVkNWZhMDQwZWExZGUyODRmNmVjNjlkNjEyOTlmNjcxMDU5In1dfV0sInVuaXQiOiJzYXQiLCJtZW1vIjoiVGhhbmsgeW91IHZlcnkgbXVjaC4ifQ=="
               )

      assert {:ok, _} =
               Cashu.Serializer.JSON.deserialize(
                 "cashuAeyJ0b2tlbiI6W3sibWludCI6Imh0dHBzOi8vODMzMy5zcGFjZTozMzM4IiwicHJvb2ZzIjpbeyJhbW91bnQiOjIsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6IjQwNzkxNWJjMjEyYmU2MWE3N2UzZTZkMmFlYjRjNzI3OTgwYmRhNTFjZDA2YTZhZmMyOWUyODYxNzY4YTc4MzciLCJDIjoiMDJiYzkwOTc5OTdkODFhZmIyY2M3MzQ2YjVlNDM0NWE5MzQ2YmQyYTUwNmViNzk1ODU5OGE3MmYwY2Y4NTE2M2VhIn0seyJhbW91bnQiOjgsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6ImZlMTUxMDkzMTRlNjFkNzc1NmIwZjhlZTBmMjNhNjI0YWNhYTNmNGUwNDJmNjE0MzNjNzI4YzcwNTdiOTMxYmUiLCJDIjoiMDI5ZThlNTA1MGI4OTBhN2Q2YzA5NjhkYjE2YmMxZDVkNWZhMDQwZWExZGUyODRmNmVjNjlkNjEyOTlmNjcxMDU5In1dfV0sInVuaXQiOiJzYXQiLCJtZW1vIjoiVGhhbmsgeW91IHZlcnkgbXVjaC4ifQ"
               )
    end

    test "returns error on failed deserialization" do
      assert {:error, _} =
               Cashu.Serializer.JSON.deserialize(
                 "casshuAeyJ0b2tlbiI6W3sibWludCI6Imh0dHBzOi8vODMzMy5zcGFjZTozMzM4IiwicHJvb2ZzIjpbeyJhbW91bnQiOjIsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6IjQwNzkxNWJjMjEyYmU2MWE3N2UzZTZkMmFlYjRjNzI3OTgwYmRhNTFjZDA2YTZhZmMyOWUyODYxNzY4YTc4MzciLCJDIjoiMDJiYzkwOTc5OTdkODFhZmIyY2M3MzQ2YjVlNDM0NWE5MzQ2YmQyYTUwNmViNzk1ODU5OGE3MmYwY2Y4NTE2M2VhIn0seyJhbW91bnQiOjgsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6ImZlMTUxMDkzMTRlNjFkNzc1NmIwZjhlZTBmMjNhNjI0YWNhYTNmNGUwNDJmNjE0MzNjNzI4YzcwNTdiOTMxYmUiLCJDIjoiMDI5ZThlNTA1MGI4OTBhN2Q2YzA5NjhkYjE2YmMxZDVkNWZhMDQwZWExZGUyODRmNmVjNjlkNjEyOTlmNjcxMDU5In1dfV0sInVuaXQiOiJzYXQiLCJtZW1vIjoiVGhhbmsgeW91LiJ9"
               )

      assert {:error, _} =
               Cashu.Serializer.JSON.deserialize(
                 "eyJ0b2tlbiI6W3sibWludCI6Imh0dHBzOi8vODMzMy5zcGFjZTozMzM4IiwicHJvb2ZzIjpbeyJhbW91bnQiOjIsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6IjQwNzkxNWJjMjEyYmU2MWE3N2UzZTZkMmFlYjRjNzI3OTgwYmRhNTFjZDA2YTZhZmMyOWUyODYxNzY4YTc4MzciLCJDIjoiMDJiYzkwOTc5OTdkODFhZmIyY2M3MzQ2YjVlNDM0NWE5MzQ2YmQyYTUwNmViNzk1ODU5OGE3MmYwY2Y4NTE2M2VhIn0seyJhbW91bnQiOjgsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6ImZlMTUxMDkzMTRlNjFkNzc1NmIwZjhlZTBmMjNhNjI0YWNhYTNmNGUwNDJmNjE0MzNjNzI4YzcwNTdiOTMxYmUiLCJDIjoiMDI5ZThlNTA1MGI4OTBhN2Q2YzA5NjhkYjE2YmMxZDVkNWZhMDQwZWExZGUyODRmNmVjNjlkNjEyOTlmNjcxMDU5In1dfV0sInVuaXQiOiJzYXQiLCJtZW1vIjoiVGhhbmsgeW91LiJ9"
               )
    end
  end

  describe "token V4" do
    # FIXME this test is still broken
    test "serializes single keyset" do
      token =
        TokenV4.new(
          [
            %ProofV4{
              keyset_id: :binary.decode_hex("00ad268c4d1f5826"),
              amount: 1,
              secret: "9a6dbb847bd232ba76db0df197216b29d3b8cc14553cd27827fc1cc942fedb4e",
              signature:
                :binary.decode_hex(
                  "038618543ffb6b8695df4ad4babcde92a34a96bdcd97dcee0d7ccf98d472126792"
                )
            }
          ],
          "https://localhost:3338",
          "sat",
          "Thank you"
        )

      {:ok, serialized} = Cashu.Serializer.V4.serialize(token)

      dbg(serialized)

      assert serialized ==
               "cashuBpGF0gaJhaUgArSaMTR9YJmFwgaNhYQFhc3hAOWE2ZGJiODQ3YmQyMzJiYTc2ZGIwZGYxOTcyMTZiMjlkM2I4Y2MxNDU1M2NkMjc4MjdmYzFjYzk0MmZlZGI0ZWFjWCEDhhhUP_trhpXfStS6vN6So0qWvc2X3O4NfM"
    end
  end
end
