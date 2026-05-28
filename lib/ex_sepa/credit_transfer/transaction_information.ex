defmodule ExSepa.CreditTransfer.TransactionInformation do
  alias ExSepa.Validation.Field, as: FieldValidation

  @moduledoc """
  Public transaction model for a single SEPA credit transfer.

  Each entry describes one creditor payment within a credit transfer batch.

  ## Required Fields

    * `:end_to_end_id` - originator reference for the transaction
    * `:amount` - amount in euro
    * `:creditor_name` - creditor/beneficiary name
    * `:creditor_iban` - creditor/beneficiary IBAN

  Optional creditor BIC, creditor address, and remittance information may also
  be provided.
  """

  @enforce_keys [:end_to_end_id, :amount, :creditor_name, :creditor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          end_to_end_id: String.t(),
          amount: number(),
          creditor_name: String.t(),
          creditor_address: ExSepa.Schema.Address.t() | nil,
          creditor_iban: String.t(),
          creditor_bic: String.t(),
          remittance_information: String.t()
        }

  defstruct [
    :end_to_end_id,
    :amount,
    :creditor_name,
    :creditor_address,
    :creditor_iban,
    creditor_bic: "",
    remittance_information: ""
  ]

  @doc """
  Validates input and builds a credit transfer transaction struct.

  Required keys are `:end_to_end_id`, `:amount`, `:creditor_name`, and
  `:creditor_iban`.

  The amount must be a positive euro value with up to two decimal places.
  Optional `:creditor_bic`, `:creditor_address`, and
  `:remittance_information` may also be provided.

  ## Example

      iex> ExSepa.CreditTransfer.TransactionInformation.new(%{
      ...>   end_to_end_id: "E2E-0001",
      ...>   amount: 125.50,
      ...>   creditor_name: "Example Supplier",
      ...>   creditor_iban: "NL62PXVC6402395035"
      ...> })
      {:ok,
       %ExSepa.CreditTransfer.TransactionInformation{
         end_to_end_id: "E2E-0001",
         amount: 125.5,
         creditor_name: "Example Supplier",
         creditor_address: nil,
         creditor_iban: "NL62PXVC6402395035",
         creditor_bic: "",
         remittance_information: ""
       }}
  """
  @spec new(%{
          :end_to_end_id => String.t(),
          :amount => number(),
          :creditor_name => String.t(),
          :creditor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(transaction_information), do: build(__MODULE__, @enforce_keys, transaction_information)

  @doc false
  def build(module, enforce_keys, transaction_information) do
    case transaction_information do
      %{
        end_to_end_id: end_to_end_id,
        amount: 0,
        creditor_name: creditor_name,
        creditor_iban: creditor_iban
      }
      when is_binary(end_to_end_id) and is_binary(creditor_name) and is_binary(creditor_iban) ->
        {:error,
         "amount must be a positive number with up to 2 decimal places, e.g. 18.2 or 18.02"}

      %{
        end_to_end_id: end_to_end_id,
        amount: amount,
        creditor_name: creditor_name,
        creditor_iban: creditor_iban
      }
      when is_binary(end_to_end_id) and is_number(amount) and is_binary(creditor_name) and
             is_binary(creditor_iban) ->
        with {:ok, new_end_to_end_id} <-
               FieldValidation.max_text(:end_to_end_id, end_to_end_id, 35),
             :ok <- FieldValidation.amount(amount),
             {:ok, new_creditor_name} <-
               FieldValidation.max_text(:creditor_name, creditor_name, 70),
             :ok <- FieldValidation.iban(creditor_iban),
             {:ok, optional_data} <- get_optional_data(transaction_information),
             :ok <-
               FieldValidation.address_mandatory(
                 String.slice(creditor_iban, 0, 2),
                 optional_data.creditor_bic,
                 optional_data.creditor_address
               ) do
          {:ok,
           struct(module, %{
             end_to_end_id: new_end_to_end_id,
             amount: amount,
             creditor_name: new_creditor_name,
             creditor_iban: creditor_iban,
             creditor_bic: optional_data.creditor_bic,
             creditor_address: optional_data.creditor_address,
             remittance_information: optional_data.remittance_information
           })}
        end

      %{
        end_to_end_id: end_to_end_id,
        amount: _amount,
        creditor_name: creditor_name,
        creditor_iban: creditor_iban
      }
      when is_binary(end_to_end_id) and is_binary(creditor_name) and is_binary(creditor_iban) ->
        {:error,
         "amount must be a positive number with up to 2 decimal places, e.g. 18.2 or 18.02"}

      _ ->
        missing_keys = enforce_keys -- Map.keys(transaction_information)

        if missing_keys == [] do
          case FieldValidation.text(
                 [
                   {:end_to_end_id, transaction_information[:end_to_end_id]},
                   {:creditor_name, transaction_information[:creditor_name]},
                   {:creditor_iban, transaction_information[:creditor_iban]}
                 ],
                 "Parameters must be strings."
               ) do
            :ok -> FieldValidation.amount(transaction_information[:amount])
            error -> error
          end
        else
          {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
        end
    end
  end

  defp get_optional_data(transaction_information) do
    with {:ok, creditor_bic} <- get_creditor_bic(transaction_information),
         {:ok, remittance_information} <- get_remittance_information(transaction_information),
         {:ok, creditor_address} <-
           ExSepa.Schema.Address.get_address(transaction_information, :creditor_address),
         :ok <- FieldValidation.bic(creditor_bic),
         {:ok, new_remittance_information} <-
           FieldValidation.optional_max_text(
             :remittance_information,
             remittance_information,
             140
           ) do
      {:ok,
       %{
         creditor_bic: creditor_bic,
         creditor_address: creditor_address,
         remittance_information: new_remittance_information
       }}
    end
  end

  defp get_creditor_bic(transaction_information) do
    case Map.fetch(transaction_information, :creditor_bic) do
      {:ok, creditor_bic} when is_binary(creditor_bic) ->
        {:ok, creditor_bic}

      {:ok, creditor_bic} ->
        FieldValidation.text([{:creditor_bic, creditor_bic}], "Parameters must be strings.")

      :error ->
        {:ok, ""}
    end
  end

  defp get_remittance_information(transaction_information) do
    case Map.fetch(transaction_information, :remittance_information) do
      {:ok, remittance_information} when is_binary(remittance_information) ->
        {:ok, remittance_information}

      {:ok, remittance_information} ->
        FieldValidation.text(
          [{:remittance_information, remittance_information}],
          "Parameters must be strings."
        )

      :error ->
        {:ok, ""}
    end
  end
end

defmodule ExSepa.CreditTransfer.TransactionInformationError do
  @moduledoc false
  defexception [:message]
end
