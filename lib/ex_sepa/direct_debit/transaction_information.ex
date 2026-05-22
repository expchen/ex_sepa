defmodule ExSepa.DirectDebit.TransactionInformation do
  alias ExSepa.Validation.Field, as: FieldValidation

  @moduledoc """
  Public transaction model for a single SEPA direct debit collection.

  Each entry describes one debtor collection within a direct debit batch.

  ## Required Fields

    * `:end_to_end_id` - creditor reference for the transaction
    * `:amount` - amount in euro
    * `:mandate_id` - unique mandate reference
    * `:mandate_signing_date` - mandate signature date
    * `:debtor_name` - debtor name
    * `:debtor_iban` - debtor IBAN

  Optional debtor BIC, debtor address, and remittance information may also be
  provided.
  """

  @enforce_keys [
    :end_to_end_id,
    :amount,
    :mandate_id,
    :mandate_signing_date,
    :debtor_name,
    :debtor_iban
  ]
  @typedoc false
  @type t :: %__MODULE__{
          end_to_end_id: String.t(),
          amount: float(),
          mandate_id: String.t(),
          mandate_signing_date: Date.t(),
          debtor_name: String.t(),
          debtor_address: ExSepa.Schema.Address.t() | nil,
          debtor_iban: String.t(),
          debtor_bic: String.t(),
          remittance_information: String.t()
        }
  defstruct [
    :end_to_end_id,
    :amount,
    :mandate_id,
    :mandate_signing_date,
    :debtor_name,
    :debtor_address,
    :debtor_iban,
    debtor_bic: "",
    remittance_information: ""
  ]

  @doc """
  Validates input and builds a direct debit transaction struct.

  Required keys are `:end_to_end_id`, `:amount`, `:mandate_id`,
  `:mandate_signing_date`, `:debtor_name`, and `:debtor_iban`.

  The amount must be a positive euro value with up to two decimal places and
  `:mandate_signing_date` must be a `Date`. Optional `:debtor_bic`,
  `:debtor_address`, and `:remittance_information` may also be provided.

  ## Example

      iex> ExSepa.DirectDebit.TransactionInformation.new(%{
      ...>   end_to_end_id: "E2E-0001",
      ...>   amount: 49.99,
      ...>   mandate_id: "MANDATE-0001",
      ...>   mandate_signing_date: ~D[2024-01-15],
      ...>   debtor_name: "Member One",
      ...>   debtor_iban: "DE88100900001234567892"
      ...> })
      {:ok,
       %ExSepa.DirectDebit.TransactionInformation{
         end_to_end_id: "E2E-0001",
         amount: 49.99,
         mandate_id: "MANDATE-0001",
         mandate_signing_date: ~D[2024-01-15],
         debtor_name: "Member One",
         debtor_address: nil,
         debtor_iban: "DE88100900001234567892",
         debtor_bic: "",
         remittance_information: ""
       }}
  """
  @spec new(%{
          :end_to_end_id => binary(),
          :amount => float(),
          :mandate_id => binary(),
          :mandate_signing_date => Date.t(),
          :debtor_name => binary(),
          :debtor_iban => binary(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(
        %{
          end_to_end_id: end_to_end_id,
          amount: amount,
          mandate_id: mandate_id,
          mandate_signing_date: %Date{} = mandate_signing_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = transaction_information
      )
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    with {:ok, new_end_to_end_id} <- FieldValidation.max_text(:end_to_end_id, end_to_end_id, 35),
         :ok <- FieldValidation.amount(amount),
         {:ok, new_mandate_id} <- FieldValidation.max_text(:mandate_id, mandate_id, 35),
         :ok <- FieldValidation.date(mandate_signing_date),
         {:ok, new_debtor_name} <- FieldValidation.max_text(:debtor_name, debtor_name, 70),
         :ok <- FieldValidation.iban(debtor_iban),
         {:ok, optional_data} <- get_optional_data(transaction_information),
         :ok <-
           FieldValidation.address_mandatory(
             String.slice(debtor_iban, 0, 2),
             optional_data.debtor_bic,
             optional_data.debtor_address
           ) do
      {:ok,
       %__MODULE__{
         end_to_end_id: new_end_to_end_id,
         amount: amount,
         mandate_id: new_mandate_id,
         mandate_signing_date: mandate_signing_date,
         debtor_name: new_debtor_name,
         debtor_iban: debtor_iban,
         debtor_bic: optional_data.debtor_bic,
         remittance_information: optional_data.remittance_information,
         debtor_address: optional_data.debtor_address
       }}
    end
  end

  def new(
        %{
          end_to_end_id: end_to_end_id,
          amount: amount,
          mandate_id: mandate_id,
          mandate_signing_date: _mandate_signing_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = _transaction_information
      )
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    {:error, "mandate_signing_date must be a date"}
  end

  def new(
        %{
          end_to_end_id: end_to_end_id,
          amount: _amount,
          mandate_id: mandate_id,
          mandate_signing_date: _mandate_signing_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = _transaction_information
      )
      when is_binary(end_to_end_id) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    {:error, "amount must be a positive number with up to 2 decimal places, e.g. 18.2 or 18.02"}
  end

  def new(transaction_information) do
    missing_keys = @enforce_keys -- Map.keys(transaction_information)

    if missing_keys == [] do
      with :ok <-
             FieldValidation.text(
               [
                 {:end_to_end_id, transaction_information[:end_to_end_id]},
                 {:mandate_id, transaction_information[:mandate_id]},
                 {:debtor_name, transaction_information[:debtor_name]},
                 {:debtor_iban, transaction_information[:debtor_iban]}
               ],
               "Parameters must be strings."
             ) do
        {:error, "Something has gone wrong: #{transaction_information}"}
      end
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end

  defp get_optional_data(transaction_information) do
    with {:ok, debtor_bic} <- get_creditor_bic(transaction_information),
         {:ok, remittance_information} <- get_remittance_information(transaction_information),
         {:ok, debtor_address} <-
           ExSepa.Schema.Address.get_address(transaction_information, :debtor_address),
         :ok <- FieldValidation.bic(debtor_bic),
         {:ok, new_remittance_information} <-
           FieldValidation.optional_max_text(:remittance_information, remittance_information, 140) do
      {:ok,
       %{
         debtor_bic: debtor_bic,
         remittance_information: new_remittance_information,
         debtor_address: debtor_address
       }}
    end
  end

  defp get_creditor_bic(transaction_information) do
    case Map.fetch(transaction_information, :debtor_bic) do
      {:ok, debtor_bic} when is_binary(debtor_bic) ->
        {:ok, debtor_bic}

      {:ok, debtor_bic} ->
        FieldValidation.text([{:debtor_bic, debtor_bic}], "Parameters must be strings.")

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

defmodule ExSepa.DirectDebit.TransactionInformationError do
  @moduledoc false
  defexception [:message]
end
