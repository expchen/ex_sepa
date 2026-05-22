defmodule ExSepa.CreditTransferInstant.TransactionInformation do
  alias ExSepa.CreditTransfer.TransactionInformation, as: CreditTransferTransactionInformation

  @moduledoc """
  Public transaction model for a single SEPA instant credit transfer.

  Each entry describes one creditor payment within an instant credit transfer
  batch.

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
          amount: float(),
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
  Validates input and builds an instant credit transfer transaction struct.

  Required keys are `:end_to_end_id`, `:amount`, `:creditor_name`, and
  `:creditor_iban`.

  The amount must be a positive euro value with up to two decimal places.
  Optional `:creditor_bic`, `:creditor_address`, and
  `:remittance_information` may also be provided.

  ## Example

      iex> ExSepa.CreditTransferInstant.TransactionInformation.new(%{
      ...>   end_to_end_id: "E2E-0001",
      ...>   amount: 15.25,
      ...>   creditor_name: "Example Merchant",
      ...>   creditor_iban: "NL62PXVC6402395035"
      ...> })
      {:ok,
       %ExSepa.CreditTransferInstant.TransactionInformation{
         end_to_end_id: "E2E-0001",
         amount: 15.25,
         creditor_name: "Example Merchant",
         creditor_address: nil,
         creditor_iban: "NL62PXVC6402395035",
         creditor_bic: "",
         remittance_information: ""
       }}
  """
  @spec new(%{
          :end_to_end_id => String.t(),
          :amount => float(),
          :creditor_name => String.t(),
          :creditor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(transaction_information),
    do:
      CreditTransferTransactionInformation.build(
        __MODULE__,
        @enforce_keys,
        transaction_information
      )
end

defmodule ExSepa.CreditTransferInstant.TransactionInformationError do
  @moduledoc false
  defexception [:message]
end
