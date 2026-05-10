defmodule ExSepa.CreditTransferInstant do
  @moduledoc """
  This module is based on the structure of the SEPA Instant Credit Transfer Scheme.
  The Instant Credit Transfer initiation message is sent by the initiating party to the debtor's intermediary or agent.
  It is used to request single or bulk instant credit transfer(s) of funds from one debtor account to one or more creditor account(s).

  ## Example 1

      # 1) Create a new instant credit transfer initiation message.
      credit_transfer =
        ExSepa.CreditTransferInstant.new(
          %{msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"})

      # 2) Add at least one payment information.
      credit_transfer =
        ExSepa.CreditTransferInstant.add_payment_information(
          credit_transfer,
          %{payment_id: "Payment-ID-0001",
          requested_execution_date: DateTime.utc_now() |> DateTime.add(60, :second),
          instruction_priority: :High,
          debtor_name: "Debtor Name",
          debtor_iban: "DE87200500001234567890"})

      # 3) Add at least one transaction information to each payment information.
      credit_transfer =
        ExSepa.CreditTransferInstant.add_transaction_information(
          credit_transfer,
          "Payment-ID-0001",
          %{end_to_end_id: "EndToEndId-0001",
            amount: 100.01,
            creditor_name: "Creditor Name",
            creditor_iban: "DE88100900001234567892",
            remittance_information: "Invoice Example 0001"})

      # 4) Receive the SEPA compliant XML message as a string.
      ExSepa.CreditTransferInstant.to_xml(credit_transfer)

  ## Example 2

      # Use the pipe operator
      ExSepa.CreditTransferInstant.new(%{msg_id: "Msg-ID-002",
        initiating_party_name: "Initiating Party"})
        |> ExSepa.CreditTransferInstant.add_payment_information(
          %{payment_id: "Payment-ID-0002",
            requested_execution_date: Date.utc_today(),
            debtor_name: "Debtor Name",
            debtor_iban: "DE87200500001234567890"})
        |> ExSepa.CreditTransferInstant.add_transaction_information(
          "Payment-ID-0002",
          %{end_to_end_id: "EndToEndId-0002",
            amount: 202.22,
            creditor_name: "Creditor Name",
            creditor_iban: "NL62PXVC6402395035",
            remittance_information: "Invoice Example 0002"})
        |> ExSepa.CreditTransferInstant.to_xml()

  ## Example 3

      # With creditor address
      ExSepa.CreditTransferInstant.new(%{msg_id: "Msg-ID-003",
        initiating_party_name: "Initiating Party"})
        |> ExSepa.CreditTransferInstant.add_payment_information(
          %{payment_id: "Payment-ID-0003",
            requested_execution_date: Date.utc_today(),
            debtor_name: "Debtor Name",
            debtor_iban: "DE87200500001234567890"})
        |> ExSepa.CreditTransferInstant.add_transaction_information(
          "Payment-ID-0003",
          %{end_to_end_id: "EndToEndId-0003",
            amount: 330.30,
            creditor_name: "Creditor Name",
            creditor_iban: "AD6510434606G73BA76MI9TE",
            creditor_bic: "CASBADADXXX",
            creditor_address: %{town_name: "Andorra la Vella", country: "AD"},
            remittance_information: "Invoice Example 0003"})
        |> ExSepa.CreditTransferInstant.to_xml()
  """

  @enforce_keys [:group_header]
  @typedoc false
  @type t :: %__MODULE__{
          group_header: ExSepa.GroupHeader.t(),
          payment_information: list(ExSepa.CreditTransferInstant.PaymentInformation.t()) | nil
        }
  defstruct [:group_header, :payment_information]

  @doc """
  Creates a new Instant Credit Transfer with a `Unique Message Id` and `Initiating Party Name`.

  The map has to contain the following keys:
    * `:msg_id` - Point to point reference, assigned by the instructing party and sent to the next party in the chain, to unambiguously identify the message. Usage: The instructing party has to make sure that MessageIdentification is unique per instructed party for a pre-agreed period.
    * `:initiating_party_name` - Party that initiates the payment. Name by which a party is known and which is usually used to identify that party. Usage: This can either be the debtor or a party that initiates the instant credit transfer on behalf of the debtor.
  """
  @spec new(%{msg_id: String.t(), initiating_party_name: String.t()}) ::
          ExSepa.CreditTransferInstant.t()
  def new(group_header) do
    case ExSepa.GroupHeader.new(group_header) do
      {:ok, parsed_group_header} ->
        %__MODULE__{group_header: parsed_group_header}

      {:error, e} ->
        raise ExSepa.GroupHeaderError, message: e
    end
  end

  @doc """
  Add Payment Information: set of characteristics that apply to the debit side of the instant credit transfer transactions.

  The map has the following keys:

    * `:payment_id` - Unique identification, as assigned by a sending party, to unambiguously identify the payment information group within the message (maximum length of 35 characters).
    * `:requested_execution_date` - The requested execution date or date-time of the SCT Inst instruction. A `Date` must be today or in the future. A `DateTime` must not be in the past.
    * `:instruction_priority` - OPTIONAL: Instruction priority for the SCT Inst instruction. Allowed values are `:High`, `:Normal`, `"HIGH"` and `"NORM"`.
    * `:debtor_name` - The Name of the Debtor, also called the Originator in the SEPA Credit Transfer Scheme (maximum length of 70 characters).
    * `:debtor_iban` - The account number (IBAN) of the Debtor.
    * `:debtor_bic` - OPTIONAL: BIC code of the Debtor PSP. If not provided, `NOTPROVIDED` is used in the Debtor Agent structure. BIC is mandatory when the Debtor PSP is located in a non-EEA SEPA country or territory.
    * `:debtor_address` - OPTIONAL: Structured or hybrid address of the Debtor. At least `:town_name` and `:country` must be used. `:address_lines` may additionally be used for up to two hybrid address lines. Address is mandatory when the Debtor PSP is located in a non-EEA SEPA country or territory. More details in `ExSepa.Address`.
  """
  @spec add_payment_information(ExSepa.CreditTransferInstant.t(), %{
          :debtor_iban => String.t(),
          :debtor_name => String.t(),
          :payment_id => String.t(),
          :requested_execution_date => Date.t() | DateTime.t(),
          optional(atom()) => any()
        }) :: ExSepa.CreditTransferInstant.t()
  def add_payment_information(
        %ExSepa.CreditTransferInstant{} = initiation,
        payment_information
      )
      when is_map(payment_information) do
    case ExSepa.CreditTransferInstant.PaymentInformation.new(payment_information) do
      {:ok, ok_payment_information} ->
        case initiation.payment_information do
          nil ->
            %__MODULE__{initiation | payment_information: [ok_payment_information]}

          payment_information_list ->
            case Enum.filter(
                   payment_information_list,
                   &(&1.payment_id == ok_payment_information.payment_id)
                 ) do
              [] ->
                %__MODULE__{
                  initiation
                  | payment_information: [ok_payment_information | payment_information_list]
                }

              _ ->
                raise ExSepa.CreditTransferInstant.PaymentInformationError,
                  message: "payment_id: #{ok_payment_information.payment_id} already exists"
            end
        end

      {:error, e} ->
        raise ExSepa.CreditTransferInstant.PaymentInformationError, message: e
    end
  end

  @doc """
  Add Transaction Information: provides information on the individual instant credit transfer transaction included in the message.

  The map has the following keys:

    * `:end_to_end_id` - The Originator's Reference of the Credit Transfer Instruction (maximum length of 35 characters). This identification is passed on unchanged throughout the end-to-end chain.
    * `:amount` - The Amount of the Credit Transfer in euro.
    * `:creditor_name` - The Name of the Creditor, also called the Beneficiary in the SEPA Credit Transfer Scheme (maximum length of 70 characters).
    * `:creditor_iban` - The account number (IBAN) of the Creditor.
    * `:creditor_bic` - OPTIONAL: BIC code of the Creditor PSP. If not provided, the Creditor Agent structure is omitted. BIC is mandatory when the Creditor PSP is located in a non-EEA SEPA country or territory.
    * `:creditor_address` - OPTIONAL: Structured or hybrid address of the Creditor. At least `:town_name` and `:country` must be used. `:address_lines` may additionally be used for up to two hybrid address lines. Address is mandatory when the Creditor PSP is located in a non-EEA SEPA country or territory. More details in `ExSepa.Address`.
    * `:remittance_information` - OPTIONAL: The Remittance Information sent by the Originator to the Beneficiary in the Credit Transfer Instruction (maximum length of 140 characters).
  """
  @spec add_transaction_information(
          ExSepa.CreditTransferInstant.t(),
          String.t(),
          %{
            :amount => float(),
            :creditor_iban => String.t(),
            :creditor_name => String.t(),
            :end_to_end_id => String.t(),
            optional(atom()) => any()
          }
        ) :: ExSepa.CreditTransferInstant.t()
  def add_transaction_information(
        %ExSepa.CreditTransferInstant{} = initiation,
        payment_id,
        transaction_information
      )
      when is_binary(payment_id) and is_map(transaction_information) do
    case initiation.payment_information do
      nil ->
        raise ExSepa.CreditTransferInstant.TransactionInformationError,
          message:
            "There is no payment information yet. Please create one using the add_payment_information command."

      payment_information_list ->
        case Enum.filter(payment_information_list, &(&1.payment_id == payment_id)) do
          [] ->
            raise ExSepa.CreditTransferInstant.TransactionInformationError,
              message: "payment_id: #{payment_id} does not exists in payment information"

          _ ->
            case ExSepa.CreditTransferInstant.TransactionInformation.new(transaction_information) do
              {:ok, ok_transaction_information} ->
                %__MODULE__{
                  initiation
                  | payment_information:
                      do_find_payment_information(
                        payment_information_list,
                        payment_id,
                        ok_transaction_information
                      )
                }

              {:error, e} ->
                raise ExSepa.CreditTransferInstant.TransactionInformationError, message: e
            end
        end
    end
  end

  defp do_find_payment_information(list, pmt_inf_id, txinf, acc \\ [])
  defp do_find_payment_information([], _pmt_inf_id, _txinf, acc), do: acc

  defp do_find_payment_information([first | rest], pmt_inf_id, txinf, acc) do
    updated_payment_information =
      if first.payment_id == pmt_inf_id do
        struct(first,
          transaction_information:
            if(first.transaction_information == nil,
              do: [txinf],
              else: [txinf | first.transaction_information]
            )
        )
      else
        first
      end

    do_find_payment_information(rest, pmt_inf_id, txinf, [updated_payment_information | acc])
  end

  @spec to_xml(ExSepa.CreditTransferInstant.t()) :: String.t()
  @doc """
  Generates the XML data in accordance with the ISO 20022 XML message standard and validates it against the XML Schema.
  """
  def to_xml(%ExSepa.CreditTransferInstant{} = initiation) do
    initiation
    |> ExSepa.CreditTransfer.CustomerCreditTransferInitiationV09.to_xml(:sct_inst)
    |> ExSepa.CreditTransfer.validate_xml()
  end
end
