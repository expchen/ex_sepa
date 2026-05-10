defmodule ExSepa.CreditTransfer.CustomerCreditTransferInitiationV09 do
  alias ExSepa.CreditTransfer.Scheme
  import XmlBuilder

  @moduledoc false
  # """
  # CustomerCreditTransferInitiationV09 (pain.001.001.09)

  # The CustomerCreditTransferInitiation message is sent by the Originator to the Originator PSP or forwarding agent.
  # It is used to request single or bulk credit transfer(s) of funds to one or various Beneficiary account(s).
  # """

  @doc false
  @spec to_xml(ExSepa.CreditTransfer.t()) :: String.t()
  def to_xml(%ExSepa.CreditTransfer{} = credit_transfer), do: to_xml(credit_transfer, :sct)

  @doc false
  @spec to_xml(
          ExSepa.CreditTransfer.t() | ExSepa.CreditTransferInstant.t(),
          Scheme.t()
        ) ::
          String.t()
  def to_xml(credit_transfer, scheme) when scheme in [:sct, :sct_inst] do
    {payment_information_xml, number_of_transactions, control_sum} =
      do_to_xml({credit_transfer.payment_information, 0, 0.0}, scheme)

    xb_document(
      element(:CstmrCdtTrfInitn, nil, [
        credit_transfer.group_header
        |> to_xml_group_header(number_of_transactions, control_sum)
        | payment_information_xml
      ])
    )
  end

  defp do_to_xml({[], number_of_transactions, control_sum}, _scheme),
    do: {[], number_of_transactions, control_sum}

  defp do_to_xml({[first | rest], number_of_transactions, control_sum}, scheme) do
    if first.transaction_information != [] do
      count = length(first.transaction_information)

      sum =
        Float.round(
          Enum.reduce(
            first.transaction_information,
            0,
            fn v, acc -> v.amount + acc end
          ) * 1.0,
          2
        )

      # new_rest is xml, and rest is payment_information.
      {new_rest, new_number_of_transactions, new_control_sum} =
        do_to_xml({rest, number_of_transactions + count, control_sum + sum}, scheme)

      {[
         to_xml_payment_information(
           first,
           count,
           sum,
           scheme
         )
         | new_rest
       ], new_number_of_transactions, new_control_sum}
    else
      do_to_xml({rest, number_of_transactions, control_sum}, scheme)
    end
  end

  defp to_xml_payment_information(
         payment_information,
         number_of_transactions,
         control_sum,
         scheme
       )
       when is_integer(number_of_transactions) and is_float(control_sum) do
    element(:PmtInf, nil, [
      element(:PmtInfId, nil, payment_information.payment_id),
      # EPC: Only "TRF" is allowed.
      element(:PmtMtd, nil, "TRF"),
      # EPC: OPTIONAL! If present and contains "true", batch booking is requested. If present and contains "false", booking per transaction is requested. If element is not present, pre-agreed customer-to-PSP conditions apply.
      # element(:BtchBookg, nil, btchBookg)
      element(:NbOfTxs, nil, number_of_transactions),
      element(:CtrlSum, nil, control_sum),
      to_xml_payment_type_information(payment_information, scheme),
      # EPC: Requested Execution Date of the Credit Transfer instruction.
      element(:ReqdExctnDt, nil, [
        to_xml_requested_execution_date(payment_information.requested_execution_date, scheme)
      ]),
      element(:Dbtr, nil, [
        element(:Nm, nil, payment_information.debtor_name),
        if payment_information.debtor_address != nil do
          to_xml_address(payment_information.debtor_address)
        end
      ]),
      element(:DbtrAcct, nil, [
        element(:Id, nil, [
          # EPC: Only IBAN is allowed.
          element(:IBAN, nil, payment_information.debtor_iban)
        ])
      ]),
      element(:DbtrAgt, nil, [
        element(:FinInstnId, nil, [
          # EPC: If the BIC is not indicated, only "NOTPROVIDED" is allowed under 'Other/Identification'.
          if payment_information.debtor_bic |> String.trim() == "" do
            element(:Othr, nil, [
              element(:Id, nil, "NOTPROVIDED")
            ])
          else
            element(:BICFI, nil, payment_information.debtor_bic)
          end
        ])
      ]),
      # EPC: Only "SLEV" is allowed. It is recommended that this element be specified at 'Payment Information' level.
      element(:ChrgBr, nil, "SLEV"),
      to_xml_transaction_information(payment_information.transaction_information)
    ])
  end

  defp to_xml_payment_type_information(payment_information, scheme) do
    local_instrument_code = Scheme.local_instrument_code(scheme)

    element(:PmtTpInf, nil, [
      if Scheme.instruction_priority_allowed?(scheme) and
           payment_information.instruction_priority != "" do
        # EPC: If present, pre-agreed customer-to-PSP conditions apply.
        element(:InstrPrty, nil, payment_information.instruction_priority)
      end,
      element(:SvcLvl, nil, [
        element(:Cd, nil, Scheme.service_level_code(scheme))
      ]),
      if local_instrument_code != nil do
        element(:LclInstrm, nil, [
          element(:Cd, nil, local_instrument_code)
        ])
      end
    ])
  end

  @doc false
  @spec xb_document({atom(), any(), any()}) :: String.t()
  def xb_document(content) do
    document(
      {:Document,
       [
         xmlns: "urn:iso:std:iso:20022:tech:xsd:pain.001.001.09",
         "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
         "xsi:schemaLocation":
           "urn:iso:std:iso:20022:tech:xsd:pain.001.001.09 pain.001.001.09.xsd"
       ], [content]}
    )
    |> generate()
  end

  @doc false
  def to_xml_group_header(
        %ExSepa.GroupHeader{} = group_header,
        number_of_transactions,
        control_sum
      ) do
    element(:GrpHdr, nil, [
      element(:MsgId, nil, group_header.msg_id),
      element(:CreDtTm, nil, DateTime.to_iso8601(DateTime.utc_now(:second))),
      element(:NbOfTxs, nil, number_of_transactions),
      element(:CtrlSum, nil, control_sum),
      element(:InitgPty, nil, [
        element(:Nm, nil, group_header.initiating_party_name)
      ])
    ])
  end

  @doc false
  @spec to_xml_transaction_information([ExSepa.CreditTransfer.TransactionInformation.t()]) ::
          list()
  def to_xml_transaction_information([]), do: []

  def to_xml_transaction_information([
        first | rest
      ]) do
    [do_to_xml_transaction_information(first) | to_xml_transaction_information(rest)]
  end

  defp do_to_xml_transaction_information(transaction_information) do
    element(:CdtTrfTxInf, nil, [
      element(:PmtId, nil, [
        # EPC: The Originator's Reference of the Credit Transfer Instruction.
        element(
          :EndToEndId,
          nil,
          if transaction_information.end_to_end_id |> String.trim() == "" do
            "NOTPROVIDED"
          else
            transaction_information.end_to_end_id |> String.trim()
          end
        )
      ]),
      element(:Amt, nil, [
        element(:InstdAmt, %{Ccy: "EUR"}, transaction_information.amount)
      ]),
      # EPC: Only 'BICFI' is allowed. If the BIC is not indicated, 'Creditor Agent' structure is not used.
      if transaction_information.creditor_bic |> String.trim() != "" do
        element(:CdtrAgt, nil, [
          element(:FinInstnId, nil, [
            element(:BICFI, nil, transaction_information.creditor_bic)
          ])
        ])
      end,
      element(:Cdtr, nil, [
        element(:Nm, nil, transaction_information.creditor_name),
        if transaction_information.creditor_address != nil do
          to_xml_address(transaction_information.creditor_address)
        end
      ]),
      element(:CdtrAcct, nil, [
        element(:Id, nil, [
          # EPC: Only IBAN is allowed.
          element(:IBAN, nil, transaction_information.creditor_iban)
        ])
      ]),
      # OPTIONAL! Current impl supports only 'Unstructured'. If empty, 'Remittance Information' is not used.
      if transaction_information.remittance_information |> String.trim() != "" do
        element(:RmtInf, nil, [
          element(:Ustrd, nil, transaction_information.remittance_information)
        ])
      end
    ])
  end

  @doc false
  @spec to_xml_address(ExSepa.Address.t()) :: {atom(), any(), any()}
  def to_xml_address(%ExSepa.Address{} = address_map), do: ExSepa.Address.to_xml(address_map)

  defp to_xml_requested_execution_date(%Date{} = date, _scheme), do: element(:Dt, nil, date)

  defp to_xml_requested_execution_date(%DateTime{} = datetime, :sct_inst),
    do: element(:DtTm, nil, DateTime.to_iso8601(datetime))
end

defmodule ExSepa.CreditTransferInstant.CustomerCreditTransferInitiationV09 do
  alias ExSepa.CreditTransfer.CustomerCreditTransferInitiationV09,
    as: CreditTransferXml

  @moduledoc false
  # """
  # CustomerCreditTransferInitiationV09 (pain.001.001.09)

  # The SCT Inst XML builder delegates to the shared credit transfer XML builder
  # and applies the instant scheme differences (`INST`, `InstrPrty`, `DtTm`).
  # """

  @doc false
  @spec to_xml(ExSepa.CreditTransferInstant.t()) :: String.t()
  def to_xml(%ExSepa.CreditTransferInstant{} = credit_transfer),
    do: CreditTransferXml.to_xml(credit_transfer, :sct_inst)
end
