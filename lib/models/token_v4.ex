defmodule Cashu.TokenV4 do
  @moduledoc """
    Create and decode tokens.
    Format: cashuB[base64_token_json]
  """
  alias Cashu.{Error, ProofV4, Validator}
  alias Cashu.Serializer.V4
  import Validator
  require Logger

  @derive Jason.Encoder
  defstruct mint: nil, unit: nil, memo: nil, token: []

  @type t :: %{
    mint: String.t(),
    unit: String.t(),
    memo: String.t(),
    token: list(ProofV4.t())
  }

  @doc """
  Create a new Cashu.Token struct from a list of Proofs, a unit, and optional memo.
  """
  def new, do: %__MODULE__{}

  def new(proof_list, mint, unit, memo \\ "") when is_list(proof_list) and is_binary(unit) do
    %__MODULE__{
      mint: mint,
      unit: unit,
      memo: memo,
      token: proof_list
    }
  end

  def new(%{"token" => tokens_list, "unit" => unit, "memo" => memo}) do
    new(tokens_list, unit, memo)
  end

  def serialize(%__MODULE__{} = token), do: V4.serialize(token)
  def serialize(_), do: {:error, :not_a_v4_token}

  @doc """
  Validate a token's content.
  """
  def validate(%{token: token_list, unit: unit, memo: memo} = token) do
    with {:ok, _valid_proofs} <- validate_token_list(token_list),
         {:ok, _} <- validate_unit(unit),
         {:ok, _} <- validate_memo(memo) do
      {:ok, token}
    else
      {:error, error} -> if(is_list(error), do: handle_errors(error), else: Error.new(error))
      err -> err
    end
  end

  def validate({:error, _} = err), do: err
  def validate(_), do: {:error, "Invalid token provided"}

  def handle_errors(errors) do
    if Enum.count(errors) > 1 do
      Enum.map(errors, fn err -> Logger.error(err) end)
      {:error, "Multiple proof validation errors received, see logs."}
    else
      Logger.error(errors)
      {:error, Enum.at(errors, 0)}
    end
  end

  @spec validate_token_list(Enum.t()) :: {:ok, Enum.t()} | {:error, Enum.t()}
  def validate_token_list(tokens) do
    Enum.map(tokens, fn items ->
      %{mint: mint_url, proofs: proofs} = items

      case validate_url(mint_url) do
        {:error, _} = err -> err
        {:ok, _} -> ProofV4.validate_proof_list(proofs)
      end
    end)
    |> collect_token_validations()
  end

  defp collect_token_validations(list, acc \\ %{ok: [], error: []})
  defp collect_token_validations([], %{ok: ok_proofs, error: []}), do: {:ok, ok_proofs}
  defp collect_token_validations([], %{ok: _, error: errors}), do: {:error, errors}

  defp collect_token_validations([head | tail], acc) do
    new_acc = Validator.collect_results(head, acc)
    collect_token_validations(tail, new_acc)
  end
end
