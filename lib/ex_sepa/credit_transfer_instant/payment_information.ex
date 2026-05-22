defmodule ExSepa.CreditTransferInstant.PaymentInformation do
  alias ExSepa.CreditTransfer.PaymentInformation, as: CreditTransferPaymentInformation

  @moduledoc """
  Public payment information model for SEPA instant credit transfer batches.

  Each payment information block groups transactions that share the same debtor
  and requested execution date or date-time.

  ## Required Fields

    * `:payment_id` - unique identifier for the payment information block
    * `:requested_execution_date` - execution date or date-time for the batch
    * `:debtor_name` - debtor/originator name
    * `:debtor_iban` - debtor/originator IBAN

  Optional instruction priority, debtor BIC, debtor address, and prebuilt
  transaction information entries may also be provided.
  """

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

  @doc """
  Validates input and builds an instant credit transfer payment information
  struct.

  Required keys are `:payment_id`, `:requested_execution_date`, `:debtor_name`,
  and `:debtor_iban`.

  The requested execution date may be either a `Date` or a `DateTime` and must
  not be in the past. Optional `:instruction_priority`, `:debtor_bic`,
  `:debtor_address`, and prebuilt `:transaction_information` entries may also
  be provided.

  ## Example

      iex> ExSepa.CreditTransferInstant.PaymentInformation.new(%{
      ...>   payment_id: "Payment-ID-0001",
      ...>   requested_execution_date: Date.utc_today(),
      ...>   debtor_name: "Example GmbH",
      ...>   debtor_iban: "DE87200500001234567890"
      ...> })
      {:ok,
       %ExSepa.CreditTransferInstant.PaymentInformation{
         payment_id: "Payment-ID-0001",
         requested_execution_date: Date.utc_today(),
         instruction_priority: "",
         debtor_name: "Example GmbH",
         debtor_address: nil,
         debtor_iban: "DE87200500001234567890",
         debtor_bic: "",
         transaction_information: []
       }}
  """
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
