defmodule ExSepa.CreditTransferInstant.PaymentInformation do
  alias ExSepa.CreditTransfer.PaymentInformation, as: CreditTransferPaymentInformation

  @moduledoc false

  @enforce_keys [:payment_id, :requested_execution_date, :debtor_name, :debtor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          payment_id: String.t(),
          requested_execution_date: Date.t() | DateTime.t(),
          instruction_priority: String.t(),
          debtor_name: String.t(),
          debtor_address: ExSepa.Schema.Address.t() | nil,
          debtor_iban: String.t(),
          debtor_bic: String.t(),
          transaction_information:
            list(ExSepa.CreditTransferInstant.TransactionInformation.t()) | nil
        }

  defstruct [
    :payment_id,
    :requested_execution_date,
    :debtor_name,
    :debtor_address,
    :debtor_iban,
    instruction_priority: "",
    debtor_bic: "",
    transaction_information: []
  ]

  @doc false
  @spec new(%{
          :payment_id => String.t(),
          :requested_execution_date => Date.t() | DateTime.t(),
          :debtor_name => String.t(),
          :debtor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(transaction_information),
    do:
      CreditTransferPaymentInformation.build(
        :sct_inst,
        __MODULE__,
        @enforce_keys,
        transaction_information
      )
end

defmodule ExSepa.CreditTransferInstant.PaymentInformationError do
  @moduledoc false
  defexception [:message]
end
