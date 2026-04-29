defmodule ExSepa.CreditTransfer.CustomerCreditTransferInitiationV09 do
  import XmlBuilder

  @moduledoc false
  # """
  # CustomerCreditTransferInitiationV09 (pain.001.001.09)

  # The CustomerCreditTransferInitiation message is sent by the Originator to the Originator PSP or forwarding agent.
  # It is used to request single or bulk credit transfer(s) of funds to one or various Beneficiary account(s).
  # """

  @doc false
  @spec to_xml(ExSepa.CreditTransfer.t()) :: String.t()
  def to_xml(%ExSepa.CreditTransfer{} = credit_transfer) do
    {info, number_of_transactions, control_sum} =
      do_to_xml({credit_transfer.payment_information, 0, 0.0})

    xb_document(
      element(:CstmrCdtTrfInitn, nil, [
        credit_transfer.group_header
        |> to_xml_group_header(number_of_transactions, control_sum)
        | info
      ])
    )
  end

  defp do_to_xml({[], number_of_transactions, control_sum}),
    do: {[], number_of_transactions, control_sum}

  defp do_to_xml(
         {[%ExSepa.CreditTransfer.PaymentInformation{} = first | rest], number_of_transactions,
          control_sum}
       ) do
    if first.transaction_information != [] do
      count = length(first.transaction_information)

      sum =
        Float.round(
          Enum.reduce(
            first.transaction_information,
            0,
            fn %ExSepa.CreditTransfer.TransactionInformation{} = v, acc ->
              v.amount + acc
            end
          ) * 1.0,
          2
        )

      {new_rest, new_number_of_transactions, new_control_sum} =
        do_to_xml({rest, number_of_transactions + count, control_sum + sum})

      {[
         to_xml_payment_information(
           first,
           count,
           sum
         )
         | new_rest
       ], new_number_of_transactions, new_control_sum}
    else
      {new_rest, new_number_of_transactions, new_control_sum} =
        do_to_xml({rest, number_of_transactions, control_sum})

      {[new_rest], new_number_of_transactions, new_control_sum}
    end
  end

  defp xb_document(content) do
    doc =
      document(
        {:Document,
         [
           xmlns: "urn:iso:std:iso:20022:tech:xsd:pain.001.001.09",
           "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
           "xsi:schemaLocation":
             "urn:iso:std:iso:20022:tech:xsd:pain.001.001.09 pain.001.001.09.xsd"
         ], [content]}
      )

    doc
    |> generate()
  end

  defp to_xml_group_header(
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

  defp to_xml_payment_information(
         %ExSepa.CreditTransfer.PaymentInformation{} = payment_information,
         number_of_transactions,
         control_sum
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
      element(:PmtTpInf, nil, [
        element(:SvcLvl, nil, [
          element(:Cd, nil, "SEPA")
        ])
      ]),
      # EPC: Requested Execution Date of the Credit Transfer instruction.
      element(:ReqdExctnDt, nil, [
        element(:Dt, nil, payment_information.requested_execution_date)
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

  @doc false
  @spec to_xml_transaction_information([ExSepa.CreditTransfer.TransactionInformation.t()]) ::
          list()
  def to_xml_transaction_information([]), do: []

  def to_xml_transaction_information([
        %ExSepa.CreditTransfer.TransactionInformation{} = first | rest
      ]) do
    [do_to_xml_transaction_information(first) | to_xml_transaction_information(rest)]
  end

  defp do_to_xml_transaction_information(
         %ExSepa.CreditTransfer.TransactionInformation{} = transaction_information
       ) do
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
      # Impl: OPTIONAL! Current impl supports only 'Unstructured'. If empty, 'Remittance Information' is not used.
      if transaction_information.remittance_information |> String.trim() != "" do
        element(:RmtInf, nil, [
          element(:Ustrd, nil, transaction_information.remittance_information)
        ])
      end
    ])
  end

  @doc false
  @spec to_xml_address(ExSepa.Address.t()) :: {atom(), any(), any()}
  def to_xml_address(%ExSepa.Address{} = address_map) do
    # Impl: Current impl renders only structured postal address fields. Hybrid and unstructured address handling is deferred to the shared address redesign.
    element(:PstlAdr, nil, [
      if address_map.department != nil do
        element(:Dept, nil, address_map.department)
      end,
      if address_map.sub_department != nil do
        element(:SubDept, nil, address_map.sub_department)
      end,
      if address_map.street_name != nil do
        element(:StrtNm, nil, address_map.street_name)
      end,
      if address_map.building_number != nil do
        element(:BldgNb, nil, address_map.building_number)
      end,
      if address_map.building_name != nil do
        element(:BldgNm, nil, address_map.building_name)
      end,
      if address_map.floor != nil do
        element(:Flr, nil, address_map.floor)
      end,
      if address_map.post_box != nil do
        element(:PstBx, nil, address_map.post_box)
      end,
      if address_map.room != nil do
        element(:Room, nil, address_map.room)
      end,
      if address_map.post_code != nil do
        element(:PstCd, nil, address_map.post_code)
      end,
      element(:TwnNm, nil, address_map.town_name),
      if address_map.town_location_name != nil do
        element(:TwnLctnNm, nil, address_map.town_location_name)
      end,
      if address_map.district_name != nil do
        element(:DstrctNm, nil, address_map.district_name)
      end,
      if address_map.country_sub_division != nil do
        element(:CtrySubDvsn, nil, address_map.country_sub_division)
      end,
      element(:Ctry, nil, address_map.country)
    ])
  end
end
