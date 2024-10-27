defmodule BDHKETest do
  use ExUnit.Case

  alias Bitcoinex.Secp256k1.{Math, Point, PrivateKey}
  alias Cashu.BDHKE

  def encode_unsigned(number) do
    number
    |> :binary.encode_unsigned()
    |> Bitcoinex.Utils.pad(32, :leading)
    |> Base.encode16(case: :lower)
  end

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

  describe "Alice, Bob and Carol Tests" do
    setup do
      secret_msg = "test_message"

      {alice_d, _} =
        Integer.parse("0000000000000000000000000000000000000000000000000000000000000001", 16)

      {:ok, alice_private_key} = PrivateKey.new(alice_d)

      {bob_d, _} =
        Integer.parse("0000000000000000000000000000000000000000000000000000000000000001", 16)

      {:ok, bob_private_key} = PrivateKey.new(bob_d)

      {:ok, bob_a} =
        Base.decode16("0000000000000000000000000000000000000000000000000000000000000001",
          case: :lower
        )

      {:ok, bob_public_key} = Point.parse_public_key(<<2>> <> bob_a)

      {:ok,
       secret_msg: secret_msg,
       alice_private_key: alice_private_key,
       bob_private_key: bob_private_key,
       bob_public_key: bob_public_key}
    end

    test "Step 1 - Alice generate blinded message", state do
      {:ok, b_, r} = BDHKE.blind_point(state[:secret_msg], state[:alice_private_key])

      assert r == state[:alice_private_key].d

      assert Point.serialize_public_key(b_) ==
               "025cc16fe33b953e2ace39653efb3e7a7049711ae1d8a2f7a9108753f1cdea742b"
    end

    test "Step 2 - Bob sign the blinded message", state do
      {:ok, b_, _} = BDHKE.blind_point(state[:secret_msg], state[:alice_private_key])
      {:ok, c_, _e, _s} = BDHKE.sign_blinded_point(b_, state[:bob_private_key])

      assert Point.serialize_public_key(c_) ==
               "025cc16fe33b953e2ace39653efb3e7a7049711ae1d8a2f7a9108753f1cdea742b"
    end

    test "Step 3 - Alice generate proof", state do
      {:ok, b_, _} = BDHKE.blind_point(state[:secret_msg], state[:alice_private_key])
      {:ok, c_, _e, _s} = BDHKE.sign_blinded_point(b_, state[:bob_private_key])

      r = state[:alice_private_key].d
      a = state[:bob_public_key]
      {:ok, c} = BDHKE.generate_proof(c_, r, a)

      assert Point.serialize_public_key(c) ==
               "0271bf0d702dbad86cbe0af3ab2bfba70a0338f22728e412d88a830ed0580b9de4"
    end

    test "hash of public keys", state do
      {:ok, r1_a} =
        Base.decode16("0000000000000000000000000000000000000000000000000000000000000001",
          case: :lower
        )

      {:ok, r1} = Point.parse_public_key(<<2>> <> r1_a)

      {:ok, r2_a} =
        Base.decode16("0000000000000000000000000000000000000000000000000000000000000001",
          case: :lower
        )

      {:ok, r2} = Point.parse_public_key(<<2>> <> r2_a)

      {:ok, c_a} =
        Base.decode16("02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2",
          case: :lower
        )

      {:ok, c_} = Point.parse_public_key(c_a)

      hash = BDHKE.hash_pubkeys([r1, r2, state[:bob_public_key], c_])

      assert hash |> Base.encode16(case: :lower) ==
               "a4dc034b74338c28c6bc3ea49731f2a24440fc7c4affc08b31a93fc9fbe6401e"
    end

    test "Bob create DLEQ", state do
      {:ok, b_, _} = BDHKE.blind_point(state[:secret_msg], state[:alice_private_key])

      a = state[:bob_private_key]
      # using alice_private_key as it has the same value as the reference implementation.
      p_bytes = state[:alice_private_key]

      {:ok, e, s} = BDHKE.mint_create_dleq(b_, a, p_bytes)

      assert e |> encode_unsigned() ==
               "a608ae30a54c6d878c706240ee35d4289b68cfe99454bbfa6578b503bce2dbe1"

      assert s |> encode_unsigned() ==
               "a608ae30a54c6d878c706240ee35d4289b68cfe99454bbfa6578b503bce2dbe2"

      # change `a`
      {pk, _} =
        Integer.parse("0000000000000000000000000000000000000000000000000000000000001111", 16)
      {:ok, a} = PrivateKey.new(pk)

      {:ok, e, s} = BDHKE.mint_create_dleq(b_, a, p_bytes)

      assert e |> encode_unsigned() ==
        "076cbdda4f368053c33056c438df014d1875eb3c8b28120bece74b6d0e6381bb"

      assert s |> encode_unsigned() ==
        "b6d41ac1e12415862bf8cace95e5355e9262eab8a11d201dadd3b6e41584ea6e"
    end

    test "Alice direct verify DLEQ", state do
      a = PrivateKey.to_point(state[:bob_private_key])
      {:ok, b_, _} = BDHKE.blind_point(state[:secret_msg], state[:alice_private_key])
      {:ok, c_, e, s} = BDHKE.sign_blinded_point(b_, state[:bob_private_key])

      assert BDHKE.verify_dleq(b_, c_, e, s, a)
    end

    test "Bob verify unblinded signature is valid", state do
      a = PrivateKey.to_point(state[:bob_private_key])
      assert a |> Point.serialize_public_key() == "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"

      {:ok, b_, _} = BDHKE.blind_point(state[:secret_msg], state[:alice_private_key])
      {:ok, c_, e, s} = BDHKE.sign_blinded_point(b_, state[:bob_private_key])
      assert BDHKE.verify_dleq(b_, c_, e, s, a)

      r = state[:alice_private_key].d
      {:ok, c} = BDHKE.generate_proof(c_, r, a)

      #Bob check the sent proof with the secret msg
      assert BDHKE.is_valid?(state[:bob_private_key], c, state[:secret_msg])
    end
  end

  describe "Blind DH Key exchange" do
    setup do
      secret_message = "supersecretmsg"

      secret_point = %Point{
        x:
          165_428_529_674_300_850_711_470_358_265_510_981_046_187_411_838_897_604_847_603_594_356_633_567_269_946_251_154_765_544_582_914_210_265_139_411_058_617_014_014_955_866_800_369_281_731_932_606_973_475_449_889_077,
        y:
          44_992_216_485_837_052_131_086_138_767_480_732_229_397_183_462_071_939_149_692_371_149_403_731_458_246,
        z: 0
      }

      blinding_factor = %PrivateKey{
        d:
          59_819_602_499_272_341_213_100_391_504_737_638_579_839_792_882_958_090_364_791_788_378_265_695_942_797
      }

      bob_privkey = %PrivateKey{
        d:
          47_437_669_545_325_492_424_569_563_321_792_550_575_318_170_499_197_377_132_293_058_206_264_810_090_011
      }

      bob_pubkey = PrivateKey.to_point(bob_privkey)

      blinded_point = %Point{
        x:
          77_159_601_893_659_699_623_859_993_964_889_035_746_054_909_217_819_999_318_193_247_812_104_419_894_542,
        y:
          34_189_797_318_307_817_155_934_877_944_290_070_857_876_974_320_905_663_111_100_833_630_285_077_249_997,
        z: 0
      }

      commitment_point = %Point{
        x:
          29_906_010_561_444_270_207_077_048_185_412_362_687_772_004_356_240_833_255_426_061_106_935_787_681_379,
        y:
          107_902_611_057_875_541_122_879_735_170_648_486_454_545_598_618_359_320_247_388_931_673_998_630_230_067,
        z: 0
      }

      unblinded_point = %Bitcoinex.Secp256k1.Point{
        x:
          6_926_516_631_442_612_919_967_864_756_916_302_857_632_671_603_926_317_444_090_266_071_882_437_486_257,
        y:
          27_974_101_066_102_506_144_090_919_693_723_041_956_919_162_837_028_908_850_516_403_602_143_893_207_305,
        z: 0
      }

      {:ok,
       secret_msg: secret_message,
       secret_point: secret_point,
       blinding_factor: blinding_factor,
       bob_privkey: bob_privkey,
       bob_pubkey: bob_pubkey,
       blinded_point: blinded_point,
       commitment_point: commitment_point,
       unblinded_point: unblinded_point}
    end

    test "hash a message to the curve", context do
      {:ok, %Point{} = point} = BDHKE.hash_to_curve(context[:secret_msg])
      assert point == context[:secret_point]
    end

    test "create a blind point from two secrets", context do
      expected_point = context[:blinded_point]
      {:ok, blinded_point, _} = BDHKE.blind_point(context[:secret_msg], context[:blinding_factor])

      assert blinded_point == expected_point
    end

    test "sign a blinded point, return c_", context do
      expected_c_ = context[:commitment_point]
      {:ok, c_, _e, _s} = BDHKE.sign_blinded_point(context[:blinded_point], context[:bob_privkey])
      assert c_ == expected_c_
    end

    test "unblind signature", context do
      expected_c = context[:unblinded_point]

      {:ok, c} =
        BDHKE.generate_proof(
          context[:commitment_point],
          context[:blinding_factor].d,
          context[:bob_pubkey]
        )

      assert expected_c == c
    end

    test "create and verify DLEQ", context do
      {:ok, e, s} = BDHKE.mint_create_dleq(context[:blinded_point], context[:bob_privkey])
      assert is_integer(e)
      assert is_integer(s)

      assert BDHKE.verify_dleq(
               context[:blinded_point],
               context[:commitment_point],
               e,
               s,
               context[:bob_pubkey]
             )
    end
  end

  describe "BDHKE utility functions" do
    test "negate a point" do
      {:ok, %Point{x: xb} = b_point, _} = BDHKE.blind_point("supersecretmsg2")
      {:ok, %Point{x: xn} = negated} = BDHKE.negate(b_point)

      assert xb == xn
      assert %Point{x: 0, y: 0, z: 0} == Math.add(b_point, negated)
    end

    test "hash a set of pubkeys together" do
      func =
        with {:ok, privkey} <- BDHKE.random_number() |> PrivateKey.new(),
             do: PrivateKey.to_point(privkey)

      hash = Stream.repeatedly(fn -> func end) |> Enum.take(4) |> BDHKE.hash_pubkeys()
      assert byte_size(hash) == 32
    end
  end
end
