defmodule CashuTest do
  alias Bitcoinex.Secp256k1
  use ExUnit.Case, async: true

  describe "create_output/3" do
    test "succeeds for multiple inputs" do
      secrets = [
        "99323811477239c9ac8797be8bc701f6c88b8129",
        "88aec2f16cfb616748e375f17260310895c3383d",
        "a7edf5f59cf413bce680d4f6289ee51953a97d26",
        "6d2e892270a4ffd2e01eb8b9003496d90d6be34c"
      ]

      blinding_factor_hexes = [
        "afe42aafc36b237a4cef6d14d9968de5f97cb1ea5c9450eef147e9d8f8f92d16",
        "02ce638c48e1eb1d4d820c9d72cd976df731e7d8527a59032ffa89642ea2e370",
        "9ff729a07f14babfcde230a8357ca88fb1f526e83d01306b6f0e659583474fe9",
        "ceb4bd807629aaf7bdc13af20badbd29ab6c998c4211ac053433fc4d1cd1a922"
      ]

      b_primes = [
        "02d2134b1f5378d123ca044ea72294a5b9654f4f28a2efce568d3c278215a991ae",
        "02ce221987430bf129289cf2342ef4e561e8513c187e45d06b5869623e08c32e52",
        "02e30e74f985c929ed1eb68e634c2e067dbf0d053ae6e1fe1a313c86176a7d8d24",
        "022a606493a5019a548f3db0fd9ef558525762254ac0bb467ad4d6fd573025b941"
      ]

      [secrets, blinding_factor_hexes, b_primes]
      |> Enum.zip()
      |> Enum.each(fn {secret, blinding_factor_hex, b_prime} ->
        output = Cashu.create_output(secret, 1, blinding_factor_hex, "test_keyset")

        assert output.b_prime == b_prime
        assert output.amount == 1
        assert output.id == "test_keyset"
        assert output.secret == secret
      end)
    end
  end

  describe "create_proof/5" do
    test "suceeds as well" do
      secrets = [
        "0e2744787ceb6b2c3c3010c5f43f8716d21e984b",
        "e6a0cc3a68d65ed69da8c8bff62e0c6705fa1175",
        "6409e4c036eeef974f3ae0639f591818a62c9d6c",
        "61a295e98804216d810828f181d4d63080f68a0d"
      ]

      blinding_factors = [
        "9666359ba06b55cf83dbc3e07f72401152496306f4e435b9ec101f8d033d7f4c",
        "438b0fb011252446554a0b13e4501be4af30f33040f0bb476c2f871669583184",
        "9fc1029028b4759ae17189f9b6f598216c2f25da5f8f61cb9a5a819539a40f27",
        "5cdea958def4b975532bf0b40827f1a294da7e4dc93b7d5d6976267e83139a06"
      ]

      mint_privkey = [
        "534db01882fc438cbcf607788ab0273e4db939e3d518303fc8bfd59a6caa766c",
        "09c7e5c441e7bbf41d7b731ac3213852c118768fc58487cc01334dbda79436d4",
        "562833c44cfaede593f55999f180b14f1fe8cba35238bcbe3dbbd8816711318d",
        "58651e5848d1342fb82c0b69e0dd6c9adb618e157bd5a6dff341647477838792"
      ]

      signatures = [
        "02f6b0bda857f3a0665074a02609fa3040634c6208eed7cb205d120220ab576dd0",
        "033aec27cbeb0a2aa9bcd3aefe51dce0820151a15ac15d470e33634a669cef3bf0",
        "022cd526799b66fbb26f3a1008d398826cec59e36de6c8df8e061bf858756a62db",
        "026064e4a349cf84bd5844094b51fdb97cb9ce7ac104d8c2324ce89249cdce38db"
      ]

      [secrets, blinding_factors, mint_privkey, signatures]
      |> Enum.zip()
      |> Enum.each(fn {secret, blinding_factor, mint_privkey, signature} ->
        keyset_id = "test_keyset"

        {:ok, mint_privkey} = mint_privkey |> String.to_integer(16) |> Secp256k1.PrivateKey.new()
        output = Cashu.create_output(secret, 1, blinding_factor, keyset_id)
        promise = Cashu.sign_output(output.b_prime, 1, keyset_id, mint_privkey)

        mint_pubkey =
          Secp256k1.PrivateKey.to_point(mint_privkey) |> Secp256k1.Point.serialize_public_key()

        proof =
          Cashu.create_proof(promise.c_prime, blinding_factor, secret, 1, keyset_id, mint_pubkey)

        assert proof.amount == 1
        assert proof.keyset_id == keyset_id
        assert proof.secret == secret
        assert proof.signature == signature
      end)
    end
  end
end
