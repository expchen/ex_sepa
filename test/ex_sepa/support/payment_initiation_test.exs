defmodule ExSepa.Support.PaymentInitiationTest do
  use ExUnit.Case, async: true

  alias ExSepa.Support.PaymentInitiation

  describe "add_payment_information/4" do
    test "raises on duplicate payment_id" do
      payment_id = "Pmt-ID-001"

      assert_raise ExSepa.CreditTransfer.PaymentInformationError,
                   "payment_id: #{payment_id} already exists",
                   fn ->
                     credit_transfer_shell()
                     |> PaymentInitiation.add_payment_information(
                       %{
                         payment_id: payment_id,
                         requested_execution_date: Date.utc_today(),
                         debtor_name: "Debtor Name",
                         debtor_iban: "DE87200500001234567890"
                       },
                       ExSepa.CreditTransfer.PaymentInformation,
                       ExSepa.CreditTransfer.PaymentInformationError
                     )
                     |> PaymentInitiation.add_payment_information(
                       %{
                         payment_id: payment_id,
                         requested_execution_date: Date.utc_today(),
                         debtor_name: "Another Debtor",
                         debtor_iban: "DE88100900001234567892"
                       },
                       ExSepa.CreditTransfer.PaymentInformation,
                       ExSepa.CreditTransfer.PaymentInformationError
                     )
                   end
    end

    test "prepends payment information entries" do
      initiation =
        credit_transfer_shell()
        |> PaymentInitiation.add_payment_information(
          %{
            payment_id: "Pmt-ID-001",
            requested_execution_date: Date.utc_today(),
            debtor_name: "Debtor One",
            debtor_iban: "DE87200500001234567890"
          },
          ExSepa.CreditTransfer.PaymentInformation,
          ExSepa.CreditTransfer.PaymentInformationError
        )
        |> PaymentInitiation.add_payment_information(
          %{
            payment_id: "Pmt-ID-002",
            requested_execution_date: Date.utc_today(),
            debtor_name: "Debtor Two",
            debtor_iban: "DE88100900001234567892"
          },
          ExSepa.CreditTransfer.PaymentInformation,
          ExSepa.CreditTransfer.PaymentInformationError
        )

      assert Enum.map(initiation.payment_information, & &1.payment_id) == ["Pmt-ID-002", "Pmt-ID-001"]
    end
  end

  describe "add_transaction_information/5" do
    test "raises when payment information does not exist yet" do
      assert_raise ExSepa.CreditTransfer.TransactionInformationError,
                   "There is no payment information yet. Please create one using the add_payment_information command.",
                   fn ->
                     PaymentInitiation.add_transaction_information(
                       credit_transfer_shell(),
                       "Pmt-ID-001",
                       %{
                         end_to_end_id: "EndToEndId-0001",
                         amount: 100.01,
                         creditor_name: "Creditor Name",
                         creditor_iban: "DE88100900001234567892"
                       },
                       ExSepa.CreditTransfer.TransactionInformation,
                       ExSepa.CreditTransfer.TransactionInformationError
                     )
                   end
    end

    test "raises when payment_id cannot be found" do
      assert_raise ExSepa.CreditTransfer.TransactionInformationError,
                   "payment_id: Missing-Payment-ID does not exists in payment information",
                   fn ->
                     credit_transfer_shell()
                     |> PaymentInitiation.add_payment_information(
                       %{
                         payment_id: "Pmt-ID-001",
                         requested_execution_date: Date.utc_today(),
                         debtor_name: "Debtor Name",
                         debtor_iban: "DE87200500001234567890"
                       },
                       ExSepa.CreditTransfer.PaymentInformation,
                       ExSepa.CreditTransfer.PaymentInformationError
                     )
                     |> PaymentInitiation.add_transaction_information(
                       "Missing-Payment-ID",
                       %{
                         end_to_end_id: "EndToEndId-0001",
                         amount: 100.01,
                         creditor_name: "Creditor Name",
                         creditor_iban: "DE88100900001234567892"
                       },
                       ExSepa.CreditTransfer.TransactionInformation,
                       ExSepa.CreditTransfer.TransactionInformationError
                     )
                   end
    end

    test "prepends transactions and keeps them on the matching payment block" do
      initiation =
        credit_transfer_shell()
        |> PaymentInitiation.add_payment_information(
          %{
            payment_id: "Pmt-ID-001",
            requested_execution_date: Date.utc_today(),
            debtor_name: "Debtor One",
            debtor_iban: "DE87200500001234567890"
          },
          ExSepa.CreditTransfer.PaymentInformation,
          ExSepa.CreditTransfer.PaymentInformationError
        )
        |> PaymentInitiation.add_payment_information(
          %{
            payment_id: "Pmt-ID-002",
            requested_execution_date: Date.utc_today(),
            debtor_name: "Debtor Two",
            debtor_iban: "DE88100900001234567892"
          },
          ExSepa.CreditTransfer.PaymentInformation,
          ExSepa.CreditTransfer.PaymentInformationError
        )
        |> PaymentInitiation.add_transaction_information(
          "Pmt-ID-001",
          %{
            end_to_end_id: "EndToEndId-0001",
            amount: 100.01,
            creditor_name: "Creditor One",
            creditor_iban: "DE88100900001234567892"
          },
          ExSepa.CreditTransfer.TransactionInformation,
          ExSepa.CreditTransfer.TransactionInformationError
        )
        |> PaymentInitiation.add_transaction_information(
          "Pmt-ID-001",
          %{
            end_to_end_id: "EndToEndId-0002",
            amount: 200.02,
            creditor_name: "Creditor Two",
            creditor_iban: "NL62PXVC6402395035"
          },
          ExSepa.CreditTransfer.TransactionInformation,
          ExSepa.CreditTransfer.TransactionInformationError
        )

      second_payment = Enum.find(initiation.payment_information, &(&1.payment_id == "Pmt-ID-002"))
      first_payment = Enum.find(initiation.payment_information, &(&1.payment_id == "Pmt-ID-001"))

      assert second_payment.transaction_information == []

      assert Enum.map(first_payment.transaction_information, & &1.end_to_end_id) == [
               "EndToEndId-0002",
               "EndToEndId-0001"
             ]
    end
  end

  defp credit_transfer_shell do
    PaymentInitiation.new(ExSepa.CreditTransfer, %{
      msg_id: "Msg-ID-001",
      initiating_party_name: "Initiating Party"
    })
  end
end
