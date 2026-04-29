defmodule ExSepa.CreditTransfer.PaymentInformation do
  alias ExSepa.Validation

  @moduledoc false
  # """
  # Payment Information: Set of characteristics that apply to the debit side of the payment transactions included in the credit transfer transaction initiation.
  # """

  @enforce_keys [:payment_id, :requested_execution_date, :debtor_name, :debtor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          payment_id: String.t(),
          requested_execution_date: Date.t(),
          debtor_name: String.t(),
          debtor_address: ExSepa.Address.t() | nil,
          debtor_iban: String.t(),
          debtor_bic: String.t(),
          transaction_information: list(ExSepa.CreditTransfer.TransactionInformation.t()) | nil
        }

  defstruct [
    :payment_id,
    :requested_execution_date,
    :debtor_name,
    :debtor_address,
    :debtor_iban,
    debtor_bic: "",
    transaction_information: []
  ]

  @doc false
  # """
  # Add Payment Information: Set of characteristics that apply to the debit side of the payment transactions included in the credit transfer transaction initiation.

  # The map has the following keys:

  #   * `:payment_id` - Unique identification, as assigned by a sending party, to unambiguously identify the payment information group within the message (maximum length of 35 characters).
  #   * `:requested_execution_date` - The Requested Execution Date of the Credit Transfer instruction (ISODate). The date must be today or a future date.
  #   * `:debtor_name` - The Name of the Debtor / Originator (maximum length of 70 characters).
  #   * `:debtor_iban` - The account number (IBAN) of the Debtor / Originator.
  #   * `:debtor_bic` - OPTIONAL: BIC code of the Debtor PSP. Only mandatory when the Debtor PSP is located in a non-EEA SEPA country or territory.
  #   * `:debtor_address` - OPTIONAL: Structured address. Only mandatory when the Debtor PSP is located in a non-EEA SEPA country or territory. At least `:town_name` and `:country` must be used. More details in `ExSepa.Address`.
  # """
  @spec new(%{
          :payment_id => String.t(),
          :requested_execution_date => Date.t(),
          :debtor_name => String.t(),
          :debtor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(
        %{
          payment_id: payment_id,
          requested_execution_date: %Date{} = requested_execution_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = payment_information
      )
      when is_binary(payment_id) and is_binary(debtor_name) and is_binary(debtor_iban) do
    with {:ok, new_payment_id} <- Validation.max_text(:payment_id, payment_id, 35),
         :ok <- requested_execution_date(requested_execution_date),
         {:ok, new_debtor_name} <- Validation.max_text(:debtor_name, debtor_name, 70),
         :ok <- Validation.iban(debtor_iban),
         {:ok, optional_data} <- get_optional_data(payment_information),
         :ok <-
           Validation.address_mandatory(
             String.slice(debtor_iban, 0, 2),
             optional_data.debtor_bic,
             optional_data.debtor_address
           ) do
      {:ok,
       %__MODULE__{
         payment_id: new_payment_id,
         requested_execution_date: requested_execution_date,
         debtor_name: new_debtor_name,
         debtor_iban: debtor_iban,
         debtor_bic: optional_data.debtor_bic,
         debtor_address: optional_data.debtor_address,
         transaction_information: optional_data.transaction_information
       }}
    end
  end

  def new(
        %{
          payment_id: payment_id,
          requested_execution_date: _requested_execution_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = _payment_information
      )
      when is_binary(payment_id) and is_binary(debtor_name) and is_binary(debtor_iban) do
    {:error, "Parameter requested_execution_date must be a date"}
  end

  def new(payment_information) do
    missing_keys = @enforce_keys -- Map.keys(payment_information)

    if missing_keys == [] do
      with :ok <-
             Validation.text(
               [
                 {:payment_id, payment_information[:payment_id]},
                 {:debtor_name, payment_information[:debtor_name]},
                 {:debtor_iban, payment_information[:debtor_iban]}
               ],
               "Parameters must be strings."
             ) do
        {:error, "Something has gone wrong: #{payment_information}"}
      end
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end

  defp requested_execution_date(%Date{} = date) do
    case Date.compare(date, Date.utc_today()) do
      :lt -> {:error, "The requested execution date must not be in the past."}
      _ -> :ok
    end
  end

  defp get_optional_data(payment_information) do
    with {:ok, debtor_bic} <- get_debtor_bic(payment_information),
         {:ok, transaction_information} <- get_transaction_information(payment_information),
         {:ok, debtor_address} <-
           ExSepa.Address.get_address(payment_information, :debtor_address),
         :ok <- Validation.bic(debtor_bic) do
      {:ok,
       %{
         debtor_bic: debtor_bic,
         debtor_address: debtor_address,
         transaction_information: transaction_information
       }}
    end
  end

  defp get_debtor_bic(payment_information) do
    case Map.fetch(payment_information, :debtor_bic) do
      {:ok, debtor_bic} when is_binary(debtor_bic) ->
        {:ok, debtor_bic}

      {:ok, debtor_bic} ->
        Validation.text([{:debtor_bic, debtor_bic}], "Parameters must be strings.")

      :error ->
        {:ok, ""}
    end
  end

  defp get_transaction_information(payment_information) do
    case Map.fetch(payment_information, :transaction_information) do
      {:ok, transaction_information} when is_list(transaction_information) ->
        {:ok, transaction_information}

      :error ->
        {:ok, []}
    end
  end
end

defmodule ExSepa.CreditTransfer.PaymentInformationError do
  @moduledoc false
  defexception [:message]
end
