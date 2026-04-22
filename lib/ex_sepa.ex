defmodule ExSepa do
  @moduledoc false
  # """
  # Documentation for `ExSepa`.

  # `ExSepa.DirectDebit` enables the creation of SEPA core direct debits.
  # """

  @doc false
  def example_one do
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
  def example_two do
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
  def example_three do
    # With debtor address
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
        debtor_address: %{town_name: "Andorra la Vella", country: "AD"},
        remittance_information: "Invoice Example 0003"
      }
    )
    |> ExSepa.DirectDebit.to_xml()
  end
end
