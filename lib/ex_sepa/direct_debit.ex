defmodule ExSepa.DirectDebit do
  @moduledoc """
  This module is based on the structure of the SEPA Core Direct Debit Scheme.
  The Direct Debit initiation message is sent by the initiating party to the creditor's intermediary or agent.
  It is used to request single or bulk collection(s) of funds from one or more debtor account(s) on behalf of a creditor.

  ## Example 1

      # 1) Create a new direct debit initiation message.
      direct_debit = ExSepa.DirectDebit.new(
        %{msg_id: "Msg-ID-001",
        initiating_party_name: "Initiating Party"})

      # 2) Add at least one payment information.
      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{payment_id: "Payment-ID-0001",
          due_date: Date.utc_today() |> Date.add(5),
          creditor_id: "DE00ZZZ00099999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"})

      # 3) Add at least one transaction information to each payment information.
      direct_debit =
        ExSepa.DirectDebit.add_transaction_information(
          direct_debit,
          "Payment-ID-0001",
          %{end_to_end_id: "EndToEndId-0001",
            amount: 100.01,
            mandate_id: "Mandate-Id-01",
            mandate_signing_date: ~D[2021-01-21],
            debtor_name: "Debtor Name",
            debtor_iban: "DE88100900001234567892",
            remittance_information: "Invoice Example 0001"})

      # 4) Receive the SEPA compliant XML message as a string.
      ExSepa.DirectDebit.to_xml(direct_debit)

  ## Example 2

      # Use the pipe operator
      ExSepa.DirectDebit.new(%{msg_id: "Msg-ID-002",
        initiating_party_name: "Initiating Party"})
        |> ExSepa.DirectDebit.add_payment_information(
          %{payment_id: "Payment-ID-0002",
            due_date: Date.utc_today() |> Date.add(5),
            creditor_id: "DE00ZZZ00099999999",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"})
        |> ExSepa.DirectDebit.add_transaction_information(
          "Payment-ID-0002",
          %{end_to_end_id: "EndToEndId-0002",
            amount: 100.01,
            mandate_id: "Mandate-Id-02",
            mandate_signing_date: ~D[2022-02-22],
            debtor_name: "Debtor Name",
            debtor_iban: "NL62PXVC6402395035",
            remittance_information: "Invoice Example 0002"})
        |> ExSepa.DirectDebit.to_xml()

  ## Example 3

      # With debtor address
      ExSepa.DirectDebit.new(%{msg_id: "Msg-ID-003",
        initiating_party_name: "Initiating Party"})
        |> ExSepa.DirectDebit.add_payment_information(
          %{payment_id: "Payment-ID-0003",
            due_date: Date.utc_today() |> Date.add(5),
            creditor_id: "DE00ZZZ00099999999",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"})
        |> ExSepa.DirectDebit.add_transaction_information(
          "Payment-ID-0003",
          %{end_to_end_id: "EndToEndId-0003",
            amount: 100.01,
            mandate_id: "Mandate-Id-03",
            mandate_signing_date: ~D[2023-03-23],
            debtor_name: "Debtor Name",
            debtor_iban: "AD6510434606G73BA76MI9TE",
            debtor_bic: "CASBADADXXX",
            debtor_address: %{town_name: "Andorra la Vella", country: "AD"},
            remittance_information: "Invoice Example 0003"})
        |> ExSepa.DirectDebit.to_xml()
  """

  @enforce_keys [:group_header]
  @typedoc false
  @type t :: %__MODULE__{
          group_header: ExSepa.Schema.GroupHeader.t(),
          payment_information: list(ExSepa.DirectDebit.PaymentInformation.t()) | nil
        }
  defstruct [:group_header, :payment_information]

  @doc """
  Creates a new Direct Debit with a `Unique Message Id` and `Initiating Party Name`.

  The map has to contain the following keys:
    * `:msg_id` - Point to point reference, assigned by the instructing party and sent to the next party in the chain, to unambiguously identify the message. Usage: The instructing party has to make sure that MessageIdentification is unique per instructed party for a pre-agreed period.
    * `:initiating_party_name` - Party that initiates the payment. Name by which a party is known and which is usually used to identify that party. Usage: This can either be the creditor or a party that initiates the direct debit on behalf of the creditor.
  """
  @spec new(%{msg_id: String.t(), initiating_party_name: String.t()}) :: ExSepa.DirectDebit.t()
  def new(group_header), do: ExSepa.Support.PaymentInitiation.new(__MODULE__, group_header)

  @doc """
  Add Payment Information: Set of characteristics that apply to the credit side of the payment transactions included in the direct debit transaction initiation.

  The map has the following keys:

    * `:payment_id` - Unique identification, as assigned by a sending party, to unambiguously identify the payment information group within the message (maximum length of 35 characters).
    * `:due_date` - The Due Date of the Collection (ISODate).
    * `:creditor_id` - Unique and unambiguous identification of a party (maximum length of 35 characters).
    * `:creditor_name` - The Name of the Creditor (maximum length of 70 characters).
    * `:creditor_iban` - The account number (IBAN) of the Creditor.
    * `:creditor_bic` - OPTIONAL: BIC code of the Creditor PSP. Under the EPC rules, this is only provided when the Creditor PSP explicitly requests it and is located in a non-EEA SEPA country or territory.
    * `:sequence_type` - OPTIONAL: Identifies the direct debit sequence. Accepted API values are `:OneOff`, `:First`, `:Recurring`, and `:Final`, which are rendered as the EPC codes `OOFF`, `FRST`, `RCUR`, and `FNAL`. The default is `:OneOff`.
    * `:creditor_address` - OPTIONAL: Structured or hybrid address. At least `:town_name` and `:country` must be used. `:address_lines` may additionally be used for up to two hybrid address lines. More details in `ExSepa.Schema.Address`.
    * `:transaction_information` - OPTIONAL: A prebuilt list of transaction structs. This can be used as an alternative to calling `add_transaction_information/3` repeatedly.
  """
  @spec add_payment_information(ExSepa.DirectDebit.t(), %{
          :creditor_iban => String.t(),
          :creditor_id => String.t(),
          :creditor_name => String.t(),
          :due_date => Date.t(),
          :payment_id => String.t(),
          optional(atom()) => any()
        }) :: ExSepa.DirectDebit.t()
  def add_payment_information(
        %ExSepa.DirectDebit{} = initiation,
        payment_information
      )
      when is_map(payment_information) do
    ExSepa.Support.PaymentInitiation.add_payment_information(
      initiation,
      payment_information,
      ExSepa.DirectDebit.PaymentInformation,
      ExSepa.DirectDebit.PaymentInformationError
    )
  end

  @doc """
  Add Transaction Information: Provides information on the individual transaction included in the message.

  The map has the following keys:

    * `:end_to_end_id` - The Creditor's Reference of the Direct Debit Transaction (maximum length of 35 characters).
    * `:amount` - The Amount of the Collection in euro.
    * `:mandate_id` - The Unique Mandate Reference (maximum length of 35 characters).
    * `:mandate_signing_date` - The Date of Signing of the Mandate (ISODate).
    * `:debtor_name` - The Name of the Debtor (maximum length of 70 characters).
    * `:debtor_iban` - The account number (IBAN) of the Debtor.
    * `:debtor_bic` - OPTIONAL: BIC code of the Debtor PSP. Only mandatory when the Creditor PSP or the Debtor PSP is located in a non-EEA SEPA country or territory.
    * `:debtor_address` - OPTIONAL: Structured or hybrid address. Only mandatory when the Creditor PSP or the Debtor PSP is located in a non-EEA SEPA country or territory. At least `:town_name` and `:country` must be used. `:address_lines` may additionally be used for up to two hybrid address lines. More details in `ExSepa.Schema.Address`.
    * `:remittance_information` - OPTIONAL: The Remittance information sent by the Creditor to the Debtor in the Collection (maximum length of 140 characters).
  """
  @spec add_transaction_information(
          ExSepa.DirectDebit.t(),
          String.t(),
          %{
            :end_to_end_id => String.t(),
            :amount => float(),
            :mandate_id => String.t(),
            :mandate_signing_date => Date.t(),
            :debtor_name => String.t(),
            :debtor_iban => String.t(),
            optional(atom()) => any()
          }
        ) :: ExSepa.DirectDebit.t()
  def add_transaction_information(
        %ExSepa.DirectDebit{} = initiation,
        payment_id,
        transaction_information
      )
      when is_binary(payment_id) and is_map(transaction_information) do
    ExSepa.Support.PaymentInitiation.add_transaction_information(
      initiation,
      payment_id,
      transaction_information,
      ExSepa.DirectDebit.TransactionInformation,
      ExSepa.DirectDebit.TransactionInformationError
    )
  end

  @doc """
  Generates the XML data in accordance with the ISO 20022 XML message standard and validates it against the XML Schema.
  """
  @spec to_xml(ExSepa.DirectDebit.t()) :: String.t()
  def to_xml(%ExSepa.DirectDebit{} = initiation) do
    xml = ExSepa.DirectDebit.CustomerDirectDebitInitiationV08.to_xml(initiation)
    ExSepa.Validation.Xml.validate(xml, "priv/xsd/pain.008.001.08_GBIC_5.xsd")
  end
end
