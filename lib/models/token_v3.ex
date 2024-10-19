defmodule Cashu.TokenV3 do
  @moduledoc """
    Create and decode tokens.
    Format: cashu[version][base64_token_json]
  """
  alias Cashu.{Error, ProofV3, Validator}
  import Validator
  require Logger

  @derive Jason.Encoder
  defstruct unit: nil, memo: nil, token: []

  @type t :: %{
    unit: String.t(),
    memo: String.t(),
    token: list(ProofV3.t())
  }

  @doc """
  Create a new Cashu.Token struct from a list of Proofs, a unit, and optional memo.
  """
  def new, do: %__MODULE__{}

  def new(tokens_list, unit, memo \\ "") when is_list(tokens_list) and is_binary(unit) do
    # check tokens_list and unit, then add
    %__MODULE__{
      unit: unit,
      memo: memo,
      token: tokens_list
    }
  end

  def new(%{"token" => tokens_list, "unit" => unit, "memo" => memo}) do
    new(tokens_list, unit, memo)
  end

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

  @spec validate_token_list(List.t()) :: {:ok, List.t()} | {:error, List.t()}
  def validate_token_list(tokens) do
    Enum.map(tokens, fn items ->
      %{mint: mint_url, proofs: proofs} = items

      case validate_url(mint_url) do
        {:error, _} = err -> err
        {:ok, _} -> ProofV3.validate_proof_list(proofs)
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
