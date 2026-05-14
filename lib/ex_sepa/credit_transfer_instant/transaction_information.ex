defmodule ExSepa.CreditTransferInstant.TransactionInformation do
  alias ExSepa.CreditTransfer.TransactionInformation, as: CreditTransferTransactionInformation

  @moduledoc false

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

  @doc false
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
