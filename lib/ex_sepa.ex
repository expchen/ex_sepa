defmodule ExSepa do
  @moduledoc """
  This module is the entry point for generating SEPA customer-to-PSP XML messages.

  Primary scheme modules:

    * `ExSepa.DirectDebit` - SEPA Core Direct Debit (`pain.008.001.08`)
    * `ExSepa.CreditTransfer` - SEPA Credit Transfer (`pain.001.001.09`)
    * `ExSepa.CreditTransferInstant` - SEPA Instant Credit Transfer (`pain.001.001.09` with `INST`)

  """

  @doc false
  def direct_debit_example_one do
    direct_debit =
      ExSepa.DirectDebit.new(%{msg_id: "Msg-ID-001", initiating_party_name: "Initiating Party"})

    direct_debit =
      ExSepa.DirectDebit.add_payment_information(
        direct_debit,
        %{
          payment_id: "Payment-ID-0001",
          due_date: Date.utc_today() |> Date.add(5),
          creditor_id: "DE00ZZZ00099999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        }
      )

    direct_debit =
      ExSepa.DirectDebit.add_transaction_information(
        direct_debit,
        "Payment-ID-0001",
        %{
          end_to_end_id: "EndToEndId-0001",
          amount: 100.01,
          mandate_id: "Mandate-Id-01",
          mandate_signing_date: ~D[2021-01-21],
          debtor_name: "Debtor Name",
          debtor_iban: "DE88100900001234567892",
          remittance_information: "Invoice Example 0001"
        }
      )

    ExSepa.DirectDebit.to_xml(direct_debit)
  end

  @doc false
  def direct_debit_example_two do
    # Use the pipe operator
    direct_debit =
      ExSepa.DirectDebit.new(%{msg_id: "Msg-ID-002", initiating_party_name: "Initiating Party"})

    direct_debit
    |> ExSepa.DirectDebit.add_payment_information(%{
      payment_id: "Payment-ID-0002",
      due_date: Date.utc_today() |> Date.add(5),
      creditor_id: "DE00ZZZ00099999999",
      creditor_name: "Creditor Name",
      creditor_iban: "DE87200500001234567890"
    })
    |> ExSepa.DirectDebit.add_transaction_information(
      "Payment-ID-0002",
      %{
        end_to_end_id: "EndToEndId-0002",
        amount: 202.22,
        mandate_id: "Mandate-Id-02",
        mandate_signing_date: ~D[2022-02-22],
        debtor_name: "Debtor Name",
        debtor_iban: "NL62PXVC6402395035",
        remittance_information: "Invoice Example 0002"
      }
    )
    |> ExSepa.DirectDebit.to_xml()
  end

  @doc false
  def direct_debit_example_three do
    # With debtor hybrid address
    direct_debit =
      ExSepa.DirectDebit.new(%{msg_id: "Msg-ID-003", initiating_party_name: "Initiating Party"})

    direct_debit
    |> ExSepa.DirectDebit.add_payment_information(%{
      payment_id: "Payment-ID-0003",
      due_date: Date.utc_today() |> Date.add(5),
      creditor_id: "DE00ZZZ00099999999",
      creditor_name: "Creditor Name",
      creditor_iban: "DE87200500001234567890"
    })
    |> ExSepa.DirectDebit.add_transaction_information(
      "Payment-ID-0003",
      %{
        end_to_end_id: "EndToEndId-0003",
        amount: 330.30,
        mandate_id: "Mandate-Id-03",
        mandate_signing_date: ~D[2023-03-23],
        debtor_name: "Debtor Name",
        debtor_iban: "AD6510434606G73BA76MI9TE",
        debtor_bic: "CASBADADXXX",
        debtor_address: %{
          town_name: "Andorra la Vella",
          country: "AD",
          address_lines: ["Carrer de la Vall 1", "Edifici Central"]
        },
        remittance_information: "Invoice Example 0003"
      }
    )
    |> ExSepa.DirectDebit.to_xml()
  end

  @doc false
  def credit_transfer_example_one do
    credit_transfer =
      ExSepa.CreditTransfer.new(%{
        msg_id: "Msg-ID-001",
        initiating_party_name: "Initiating Party"
      })

    credit_transfer =
      ExSepa.CreditTransfer.add_payment_information(
        credit_transfer,
        %{
          payment_id: "Payment-ID-0001",
          requested_execution_date: Date.utc_today(),
          debtor_name: "Debtor Name",
          debtor_iban: "DE87200500001234567890"
        }
      )

    credit_transfer =
      ExSepa.CreditTransfer.add_transaction_information(
        credit_transfer,
        "Payment-ID-0001",
        %{
          end_to_end_id: "EndToEndId-0001",
          amount: 100.01,
          creditor_name: "Creditor Name",
          creditor_iban: "DE88100900001234567892",
          remittance_information: "Invoice Example 0001"
        }
      )

    ExSepa.CreditTransfer.to_xml(credit_transfer)
  end

  @doc false
  def credit_transfer_example_two do
    # Use the pipe operator
    credit_transfer =
      ExSepa.CreditTransfer.new(%{
        msg_id: "Msg-ID-002",
        initiating_party_name: "Initiating Party"
      })

    credit_transfer
    |> ExSepa.CreditTransfer.add_payment_information(%{
      payment_id: "Payment-ID-0002",
      requested_execution_date: Date.utc_today() |> Date.add(1),
      debtor_name: "Debtor Name",
      debtor_iban: "DE87200500001234567890"
    })
    |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0002", %{
      end_to_end_id: "EndToEndId-0002",
      amount: 202.22,
      creditor_name: "Creditor Name",
      creditor_iban: "NL62PXVC6402395035",
      remittance_information: "Invoice Example 0002"
    })
    |> ExSepa.CreditTransfer.to_xml()
  end

  @doc false
  def credit_transfer_example_three do
    # With creditor hybrid address
    credit_transfer =
      ExSepa.CreditTransfer.new(%{
        msg_id: "Msg-ID-003",
        initiating_party_name: "Initiating Party"
      })

    credit_transfer
    |> ExSepa.CreditTransfer.add_payment_information(%{
      payment_id: "Payment-ID-0003",
      requested_execution_date: Date.utc_today() |> Date.add(1),
      debtor_name: "Debtor Name",
      debtor_iban: "DE87200500001234567890"
    })
    |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0003", %{
      end_to_end_id: "EndToEndId-0003",
      amount: 330.30,
      creditor_name: "Creditor Name",
      creditor_iban: "AD6510434606G73BA76MI9TE",
      creditor_bic: "CASBADADXXX",
      creditor_address: %{
        town_name: "München",
        country: "DE",
        address_lines: ["Leopoldstraße 50", "80302 München"]
      },
      remittance_information: "Invoice Example 0003"
    })
    |> ExSepa.CreditTransfer.to_xml()
  end

  @doc false
  def credit_transfer_instant_example_one do
    credit_transfer =
      ExSepa.CreditTransferInstant.new(%{
        msg_id: "Msg-ID-001",
        initiating_party_name: "Initiating Party"
      })

    credit_transfer =
      ExSepa.CreditTransferInstant.add_payment_information(
        credit_transfer,
        %{
          payment_id: "Payment-ID-0001",
          requested_execution_date: DateTime.utc_now() |> DateTime.add(60, :second),
          instruction_priority: :High,
          debtor_name: "Debtor Name",
          debtor_iban: "DE87200500001234567890"
        }
      )

    credit_transfer =
      ExSepa.CreditTransferInstant.add_transaction_information(
        credit_transfer,
        "Payment-ID-0001",
        %{
          end_to_end_id: "EndToEndId-0001",
          amount: 100.01,
          creditor_name: "Creditor Name",
          creditor_iban: "DE88100900001234567892",
          remittance_information: "Invoice Example 0001"
        }
      )

    ExSepa.CreditTransferInstant.to_xml(credit_transfer)
  end

  @doc false
  def credit_transfer_instant_example_two do
    # Use the pipe operator
    credit_transfer =
      ExSepa.CreditTransferInstant.new(%{
        msg_id: "Msg-ID-002",
        initiating_party_name: "Initiating Party"
      })

    credit_transfer
    |> ExSepa.CreditTransferInstant.add_payment_information(%{
      payment_id: "Payment-ID-0002",
      requested_execution_date: Date.utc_today(),
      debtor_name: "Debtor Name",
      debtor_iban: "DE87200500001234567890"
    })
    |> ExSepa.CreditTransferInstant.add_transaction_information("Payment-ID-0002", %{
      end_to_end_id: "EndToEndId-0002",
      amount: 202.22,
      creditor_name: "Creditor Name",
      creditor_iban: "NL62PXVC6402395035",
      remittance_information: "Invoice Example 0002"
    })
    |> ExSepa.CreditTransferInstant.to_xml()
  end

  @doc false
  def credit_transfer_instant_example_three do
    # With creditor hybrid address
    credit_transfer =
      ExSepa.CreditTransferInstant.new(%{
        msg_id: "Msg-ID-003",
        initiating_party_name: "Initiating Party"
      })

    credit_transfer
    |> ExSepa.CreditTransferInstant.add_payment_information(%{
      payment_id: "Payment-ID-0003",
      requested_execution_date: Date.utc_today(),
      debtor_name: "Debtor Name",
      debtor_iban: "DE87200500001234567890"
    })
    |> ExSepa.CreditTransferInstant.add_transaction_information("Payment-ID-0003", %{
      end_to_end_id: "EndToEndId-0003",
      amount: 330.30,
      creditor_name: "Creditor Name",
      creditor_iban: "AD6510434606G73BA76MI9TE",
      creditor_bic: "CASBADADXXX",
      creditor_address: %{
        town_name: "Berlin",
        country: "DE",
        address_lines: ["Friedrichstraße 123", "10117 Berlin"]
      },
      remittance_information: "Invoice Example 0003"
    })
    |> ExSepa.CreditTransferInstant.to_xml()
  end
end
