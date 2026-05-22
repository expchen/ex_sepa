defmodule ExSepa.CreditTransferTest do
  use ExUnit.Case, async: true
  import ExSepa.TestSupport.FactoryHelpers
  import ExSepa.TestSupport.XmlHelpers
  doctest ExSepa.CreditTransfer

  @debtor_bic "BANKDEFFXXX"
  @creditor_bic "BANKDEFFXXX"
  @remittance_information "Unstructured Remittance Information"
  @non_eea_debtor_iban "CH7280005000088877766"
  @non_eea_debtor_bic "RAIFCH22005"
  @non_eea_debtor_address %{town_name: "Bern", country: "CH"}
  @non_eea_creditor_iban "CH9300762011623852957"
  @non_eea_creditor_bic "RAIFCH22005"
  @non_eea_creditor_address %{town_name: "Zurich", country: "CH"}

  # Message setup and group header validation
  describe "ExSepa.CreditTransfer.new/1" do
    test "Generate a new credit transfer" do
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()

      assert ExSepa.CreditTransfer.new(%{
               msg_id: msg_id,
               initiating_party_name: initiating_party_name
             }) ==
               %ExSepa.CreditTransfer{
                 group_header: %ExSepa.Schema.GroupHeader{
                   msg_id: msg_id,
                   initiating_party_name: initiating_party_name
                 },
                 payment_information: nil
               }
    end

    test "Generate a new credit transfer - fail: msg_id is not a String" do
      assert_raise ExSepa.Schema.GroupHeaderError, "msg_id: must be UTF-8 encoded binary", fn ->
        ExSepa.CreditTransfer.new(%{
          msg_id: <<0xFFFF::16>>,
          initiating_party_name: example_person_name()
        })
      end
    end

    test "Generate a new credit transfer - fail: initiating_party_name is not a String" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.CreditTransfer.new(%{
                       msg_id: example_msg_id(),
                       initiating_party_name: <<0xFFFF::16>>
                     })
                   end
    end

    test "Generate a new credit transfer - fail on msg_id" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "Parameters must be strings. - msg_id: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.CreditTransfer.new(%{
                       msg_id: 1,
                       initiating_party_name: example_person_name()
                     })
                   end
    end

    test "Generate a new credit transfer - fail on initiating_party_name" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "Parameters must be strings. - initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.CreditTransfer.new(%{
                       msg_id: example_msg_id(),
                       initiating_party_name: 345
                     })
                   end
    end

    test "Generate a new credit transfer - fail on msg_id and initiating_party_name" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "Parameters must be strings. - msg_id: must be UTF-8 encoded binary - initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.CreditTransfer.new(%{
                       msg_id: 450,
                       initiating_party_name: 123_456
                     })
                   end
    end

    test "Generate a new credit transfer - fail: on msg_id length" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "msg_id: Maximum length of 35 characters",
                   fn ->
                     ExSepa.CreditTransfer.new(%{
                       msg_id: "0123456789012345678901234567890123456789",
                       initiating_party_name: example_person_name()
                     })
                   end
    end

    test "Generate a new credit transfer - fail: on initiating_party_name length" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "initiating_party_name: Maximum length of 70 characters",
                   fn ->
                     ExSepa.CreditTransfer.new(%{
                       msg_id: example_msg_id(),
                       initiating_party_name:
                         "The name of the person who has initiated the call is too long to be entered in this field."
                     })
                   end
    end
  end

  # Payment block orchestration, including duplicate identifiers and non-EEA input.
  describe "ExSepa.CreditTransfer.add_payment_information/2" do
    test "Generate a new Payment Information - :ok" do
      date = Date.utc_today()
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })

      assert ExSepa.CreditTransfer.add_payment_information(
               credit_transfer,
               %{
                 payment_id: payment_id,
                 requested_execution_date: date,
                 debtor_name: debtor_name,
                 debtor_iban: debtor_iban,
                 debtor_bic: @debtor_bic
               }
             ) == %ExSepa.CreditTransfer{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: msg_id,
                 initiating_party_name: initiating_party_name
               },
               payment_information: [
                 %ExSepa.CreditTransfer.PaymentInformation{
                   payment_id: payment_id,
                   requested_execution_date: date,
                   debtor_name: debtor_name,
                   debtor_iban: debtor_iban,
                   debtor_bic: @debtor_bic
                 }
               ]
             }
    end

    test "Generate a second new Payment Information - :ok" do
      date = Date.utc_today()
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      payment_id_two = example_payment_id()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()
      debtor_iban_two = example_eea_iban()

      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })

      assert credit_transfer
             |> ExSepa.CreditTransfer.add_payment_information(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             })
             |> ExSepa.CreditTransfer.add_payment_information(%{
               payment_id: payment_id_two,
               requested_execution_date: date |> Date.add(2),
               debtor_name: debtor_name,
               debtor_iban: debtor_iban_two
             }) == %ExSepa.CreditTransfer{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: msg_id,
                 initiating_party_name: initiating_party_name
               },
               payment_information: [
                 %ExSepa.CreditTransfer.PaymentInformation{
                   payment_id: payment_id_two,
                   requested_execution_date: date |> Date.add(2),
                   debtor_name: debtor_name,
                   debtor_iban: debtor_iban_two
                 },
                 %ExSepa.CreditTransfer.PaymentInformation{
                   payment_id: payment_id,
                   requested_execution_date: date,
                   debtor_name: debtor_name,
                   debtor_iban: debtor_iban
                 }
               ]
             }
    end

    test "Generate a second new Payment Information - fail: same payment_id" do
      date = Date.utc_today()
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })

      assert_raise ExSepa.CreditTransfer.PaymentInformationError,
                   "payment_id: #{payment_id} already exists",
                   fn ->
                     credit_transfer
                     |> ExSepa.CreditTransfer.add_payment_information(%{
                       payment_id: payment_id,
                       requested_execution_date: date,
                       debtor_name: debtor_name,
                       debtor_iban: debtor_iban
                     })
                     |> ExSepa.CreditTransfer.add_payment_information(%{
                       payment_id: payment_id,
                       requested_execution_date: date,
                       debtor_name: debtor_name,
                       debtor_iban: debtor_iban
                     })
                   end
    end

    test "Generate a new Payment Information for non-EEA debtor - :ok" do
      date = Date.utc_today()
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      debtor_name = example_person_name()

      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })

      assert ExSepa.CreditTransfer.add_payment_information(
               credit_transfer,
               %{
                 payment_id: payment_id,
                 requested_execution_date: date,
                 debtor_name: debtor_name,
                 debtor_iban: @non_eea_debtor_iban,
                 debtor_bic: @non_eea_debtor_bic,
                 debtor_address: @non_eea_debtor_address
               }
             ) == %ExSepa.CreditTransfer{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: msg_id,
                 initiating_party_name: initiating_party_name
               },
               payment_information: [
                 %ExSepa.CreditTransfer.PaymentInformation{
                   payment_id: payment_id,
                   requested_execution_date: date,
                   debtor_name: debtor_name,
                   debtor_iban: @non_eea_debtor_iban,
                   debtor_bic: @non_eea_debtor_bic,
                   debtor_address: %ExSepa.Schema.Address{
                     town_name: "Bern",
                     country: "CH"
                   }
                 }
               ]
             }
    end
  end

  # Transaction orchestration and routing into the right payment block.
  describe "ExSepa.CreditTransfer.add_transaction_information/3" do
    test "Generate a new Transaction Information - :ok" do
      date = Date.utc_today()
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()
      end_to_end_id = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: payment_id,
          requested_execution_date: date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        })

      assert ExSepa.CreditTransfer.add_transaction_information(
               credit_transfer,
               payment_id,
               %{
                 end_to_end_id: end_to_end_id,
                 amount: amount,
                 creditor_name: creditor_name,
                 creditor_iban: creditor_iban,
                 remittance_information: @remittance_information
               }
             ) ==
               %ExSepa.CreditTransfer{
                 group_header: %ExSepa.Schema.GroupHeader{
                   msg_id: msg_id,
                   initiating_party_name: initiating_party_name
                 },
                 payment_information: [
                   %ExSepa.CreditTransfer.PaymentInformation{
                     payment_id: payment_id,
                     requested_execution_date: date,
                     debtor_name: debtor_name,
                     debtor_iban: debtor_iban,
                     transaction_information: [
                       %ExSepa.CreditTransfer.TransactionInformation{
                         end_to_end_id: end_to_end_id,
                         amount: amount,
                         creditor_name: creditor_name,
                         creditor_iban: creditor_iban,
                         remittance_information: @remittance_information
                       }
                     ]
                   }
                 ]
               }
    end

    test "Generate a new Transaction Information - fail: there is no payment information" do
      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: example_msg_id(),
          initiating_party_name: example_person_name()
        })

      assert_raise ExSepa.CreditTransfer.TransactionInformationError,
                   "There is no payment information yet. Please create one using the add_payment_information command.",
                   fn ->
                     ExSepa.CreditTransfer.add_transaction_information(
                       credit_transfer,
                       "Pmt-ID-001",
                       %{
                         end_to_end_id: "EndToEndId-0001",
                         amount: 100.01,
                         creditor_name: "Creditor Name",
                         creditor_iban: "DE87200500001234567890"
                       }
                     )
                   end
    end

    test "Generate a new Transaction Information - fail: no matching payment_id" do
      date = Date.utc_today()

      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: example_msg_id(),
          initiating_party_name: example_person_name()
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Pmt-ID-001",
          requested_execution_date: date,
          debtor_name: "Debtor Name",
          debtor_iban: "DE87200500001234567890"
        })

      assert_raise ExSepa.CreditTransfer.TransactionInformationError,
                   "payment_id: Pmt-ID-002 does not exists in payment information",
                   fn ->
                     ExSepa.CreditTransfer.add_transaction_information(
                       credit_transfer,
                       "Pmt-ID-002",
                       %{
                         end_to_end_id: "EndToEndId-0001",
                         amount: 100.01,
                         creditor_name: "Creditor Name",
                         creditor_iban: "DE88100900001234567892"
                       }
                     )
                   end
    end

    test "Generate a new Transaction Information for non-EEA creditor - :ok" do
      date = Date.utc_today()
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()
      end_to_end_id = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()

      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: payment_id,
          requested_execution_date: date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        })

      assert ExSepa.CreditTransfer.add_transaction_information(
               credit_transfer,
               payment_id,
               %{
                 end_to_end_id: end_to_end_id,
                 amount: amount,
                 creditor_name: creditor_name,
                 creditor_iban: @non_eea_creditor_iban,
                 creditor_bic: @non_eea_creditor_bic,
                 creditor_address: @non_eea_creditor_address,
                 remittance_information: @remittance_information
               }
             ) ==
               %ExSepa.CreditTransfer{
                 group_header: %ExSepa.Schema.GroupHeader{
                   msg_id: msg_id,
                   initiating_party_name: initiating_party_name
                 },
                 payment_information: [
                   %ExSepa.CreditTransfer.PaymentInformation{
                     payment_id: payment_id,
                     requested_execution_date: date,
                     debtor_name: debtor_name,
                     debtor_iban: debtor_iban,
                     transaction_information: [
                       %ExSepa.CreditTransfer.TransactionInformation{
                         end_to_end_id: end_to_end_id,
                         amount: amount,
                         creditor_name: creditor_name,
                         creditor_iban: @non_eea_creditor_iban,
                         creditor_bic: @non_eea_creditor_bic,
                         creditor_address: %ExSepa.Schema.Address{
                           town_name: "Zurich",
                           country: "CH"
                         },
                         remittance_information: @remittance_information
                       }
                     ]
                   }
                 ]
               }
    end

    test "Generate two Payment Information with two Transaction Informations" do
      date = Date.utc_today()

      credit_transfer =
        ExSepa.CreditTransfer.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Pmt-ID-001",
          requested_execution_date: date,
          debtor_name: "Debtor One",
          debtor_iban: "DE87200500001234567890"
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Pmt-ID-002",
          requested_execution_date: date |> Date.add(1),
          debtor_name: "Debtor Two",
          debtor_iban: @non_eea_debtor_iban,
          debtor_bic: @non_eea_debtor_bic,
          debtor_address: @non_eea_debtor_address
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Pmt-ID-001", %{
          end_to_end_id: "EndToEndId-0001",
          amount: 100.01,
          creditor_name: "Creditor One",
          creditor_iban: "DE88100900001234567892"
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Pmt-ID-002", %{
          end_to_end_id: "EndToEndId-0002",
          amount: 200.02,
          creditor_name: "Creditor Two",
          creditor_iban: @non_eea_creditor_iban,
          creditor_bic: @non_eea_creditor_bic,
          creditor_address: @non_eea_creditor_address
        })

      assert credit_transfer == %ExSepa.CreditTransfer{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: "Msg-ID-001",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.CreditTransfer.PaymentInformation{
                   payment_id: "Pmt-ID-002",
                   requested_execution_date: date |> Date.add(1),
                   debtor_name: "Debtor Two",
                   debtor_iban: @non_eea_debtor_iban,
                   debtor_bic: @non_eea_debtor_bic,
                   debtor_address: %ExSepa.Schema.Address{town_name: "Bern", country: "CH"},
                   transaction_information: [
                     %ExSepa.CreditTransfer.TransactionInformation{
                       end_to_end_id: "EndToEndId-0002",
                       amount: 200.02,
                       creditor_name: "Creditor Two",
                       creditor_iban: @non_eea_creditor_iban,
                       creditor_bic: @non_eea_creditor_bic,
                       creditor_address: %ExSepa.Schema.Address{
                         town_name: "Zurich",
                         country: "CH"
                       },
                       remittance_information: ""
                     }
                   ]
                 },
                 %ExSepa.CreditTransfer.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   requested_execution_date: date,
                   debtor_name: "Debtor One",
                   debtor_iban: "DE87200500001234567890",
                   transaction_information: [
                     %ExSepa.CreditTransfer.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       creditor_name: "Creditor One",
                       creditor_iban: "DE88100900001234567892",
                       creditor_bic: "",
                       remittance_information: ""
                     }
                   ]
                 }
               ]
             }
    end
  end

  # End-to-end XML generation, scheme markers, and GBIC schema conformance.
  describe "ExSepa.CreditTransfer.to_xml/1" do
    test "Generate XML without BIC" do
      msg_id = example_msg_id()
      i_party = example_person_name()
      pmt_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()
      end_to_end_id = example_end_to_end_id()
      price = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      ct = ExSepa.CreditTransfer.new(%{msg_id: msg_id, initiating_party_name: i_party})

      xml =
        ct
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: pmt_id,
          requested_execution_date: date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        })
        |> ExSepa.CreditTransfer.add_transaction_information(pmt_id, %{
          end_to_end_id: end_to_end_id,
          amount: price,
          creditor_name: creditor_name,
          creditor_iban: creditor_iban
        })
        |> ExSepa.CreditTransfer.to_xml()

      assert export_xml(xml, "pain.sct.test.xml") |> File.exists?()
      assert xml =~ "<CstmrCdtTrfInitn>"
      assert xml =~ "<PmtMtd>TRF</PmtMtd>"
      assert xml =~ "<Cd>SEPA</Cd>"
      assert xml =~ "<DbtrAgt>"
      assert xml =~ "<Id>NOTPROVIDED</Id>"
      refute xml =~ "<RmtInf>"
      refute xml =~ "<CdtrAgt>"
    end

    test "Generate XML with BIC and remittance information" do
      msg_id = example_msg_id()
      i_party = example_person_name()
      pmt_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()
      end_to_end_id = example_end_to_end_id()
      price = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      ct = ExSepa.CreditTransfer.new(%{msg_id: msg_id, initiating_party_name: i_party})

      xml =
        ct
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: pmt_id,
          requested_execution_date: date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban,
          debtor_bic: @debtor_bic
        })
        |> ExSepa.CreditTransfer.add_transaction_information(pmt_id, %{
          end_to_end_id: end_to_end_id,
          amount: price,
          creditor_name: creditor_name,
          creditor_iban: creditor_iban,
          creditor_bic: @creditor_bic,
          remittance_information: @remittance_information
        })
        |> ExSepa.CreditTransfer.to_xml()

      assert xml =~ "<BICFI>#{@debtor_bic}</BICFI>"
      assert xml =~ "<BICFI>#{@creditor_bic}</BICFI>"
      assert xml =~ "<Ustrd>#{@remittance_information}</Ustrd>"
    end

    test "Generate XML with prebuilt transaction_information list" do
      {:ok, tx_one} =
        ExSepa.CreditTransfer.TransactionInformation.new(%{
          end_to_end_id: "EndToEndId-0003",
          amount: 100.01,
          creditor_name: "Creditor One",
          creditor_iban: "DE88100900001234567892"
        })

      {:ok, tx_two} =
        ExSepa.CreditTransfer.TransactionInformation.new(%{
          end_to_end_id: "EndToEndId-0004",
          amount: 200.02,
          creditor_name: "Creditor Two",
          creditor_iban: @non_eea_creditor_iban,
          creditor_bic: @non_eea_creditor_bic,
          creditor_address: @non_eea_creditor_address,
          remittance_information: "Invoice Example 0004"
        })

      xml =
        ExSepa.CreditTransfer.new(%{
          msg_id: "Msg-ID-003",
          initiating_party_name: "Initiating Party"
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Payment-ID-0003",
          requested_execution_date: Date.utc_today(),
          debtor_name: "Debtor Name",
          debtor_iban: "DE87200500001234567890",
          transaction_information: [tx_one, tx_two]
        })
        |> ExSepa.CreditTransfer.to_xml()

      assert export_xml(xml, "pain.sct.prebuilt_transactions.test.xml") |> File.exists?()
      assert length(Regex.scan(~r/<CdtTrfTxInf>/, xml)) == 2
      assert xml =~ "<NbOfTxs>2</NbOfTxs>"
      assert xml =~ "<CtrlSum>300.03</CtrlSum>"
      validate_against_gbic_5_pain_001(xml)
    end

    test "Generate XML with multiple payment information groups and transactions" do
      xml =
        ExSepa.CreditTransfer.new(%{
          msg_id: "Msg-ID-003A",
          initiating_party_name: "Initiating Party"
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Payment-ID-0003A",
          requested_execution_date: Date.utc_today(),
          debtor_name: "Debtor One",
          debtor_iban: "DE87200500001234567890"
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0003A", %{
          end_to_end_id: "EndToEndId-0003A-1",
          amount: 100.01,
          creditor_name: "Creditor One",
          creditor_iban: "DE88100900001234567892"
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Payment-ID-0003B",
          requested_execution_date: Date.utc_today() |> Date.add(1),
          debtor_name: "Debtor Two",
          debtor_iban: "DE12500105170648489890"
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0003B", %{
          end_to_end_id: "EndToEndId-0003B-1",
          amount: 200.02,
          creditor_name: "Creditor Two",
          creditor_iban: "NL62PXVC6402395035"
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0003B", %{
          end_to_end_id: "EndToEndId-0003B-2",
          amount: 50.03,
          creditor_name: "Creditor Three",
          creditor_iban: "FR7630006000011234567890189"
        })
        |> ExSepa.CreditTransfer.to_xml()

      assert length(Regex.scan(~r/<PmtInf>/, xml)) == 2
      assert length(Regex.scan(~r/<CdtTrfTxInf>/, xml)) == 3
      assert xml =~ "<NbOfTxs>3</NbOfTxs>"
      assert xml =~ "<CtrlSum>350.06</CtrlSum>"
      assert xml =~ "<PmtInfId>Payment-ID-0003A</PmtInfId>"
      assert xml =~ "<PmtInfId>Payment-ID-0003B</PmtInfId>"
      validate_against_gbic_5_pain_001(xml)
    end

    test "Generate XML with non-EEA structured addresses" do
      xml =
        ExSepa.CreditTransfer.new(%{
          msg_id: "Msg-ID-004",
          initiating_party_name: "Initiating Party"
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Payment-ID-0004",
          requested_execution_date: Date.utc_today(),
          debtor_name: "Swiss Debtor",
          debtor_iban: @non_eea_debtor_iban,
          debtor_bic: @non_eea_debtor_bic,
          debtor_address: @non_eea_debtor_address
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0004", %{
          end_to_end_id: "EndToEndId-0004",
          amount: 100.01,
          creditor_name: "Swiss Creditor",
          creditor_iban: @non_eea_creditor_iban,
          creditor_bic: @non_eea_creditor_bic,
          creditor_address: @non_eea_creditor_address
        })
        |> ExSepa.CreditTransfer.to_xml()

      assert xml =~ "<TwnNm>Bern</TwnNm>"
      assert xml =~ "<Ctry>CH</Ctry>"
      assert xml =~ "<BICFI>#{@non_eea_debtor_bic}</BICFI>"
      assert xml =~ "<BICFI>#{@non_eea_creditor_bic}</BICFI>"
      assert xml =~ "<TwnNm>Zurich</TwnNm>"
    end

    test "Generate XML with hybrid address lines" do
      xml =
        ExSepa.CreditTransfer.new(%{
          msg_id: "Msg-ID-005",
          initiating_party_name: "Initiating Party"
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Payment-ID-0005",
          requested_execution_date: Date.utc_today(),
          debtor_name: "Debtor Name",
          debtor_iban: "DE87200500001234567890"
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0005", %{
          end_to_end_id: "EndToEndId-0005",
          amount: 100.01,
          creditor_name: "Swiss Creditor",
          creditor_iban: @non_eea_creditor_iban,
          creditor_bic: @non_eea_creditor_bic,
          creditor_address: %{
            town_name: "Zurich",
            country: "CH",
            address_lines: ["Bahnhofstrasse 1", "3. Stock"]
          }
        })
        |> ExSepa.CreditTransfer.to_xml()

      assert xml =~ "<TwnNm>Zurich</TwnNm>"
      assert xml =~ "<Ctry>CH</Ctry>"
      assert xml =~ "<AdrLine>Bahnhofstrasse 1</AdrLine>"
      assert xml =~ "<AdrLine>3. Stock</AdrLine>"
    end

    test "Generate XML with 8-character BICs" do
      xml =
        ExSepa.CreditTransfer.new(%{
          msg_id: "Msg-ID-006",
          initiating_party_name: "Initiating Party"
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Payment-ID-0006",
          requested_execution_date: ~D[2026-11-14],
          debtor_name: "Debtor Name",
          debtor_iban: "DE87200500001234567890",
          debtor_bic: "BANKDEFF"
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0006", %{
          end_to_end_id: "EndToEndId-0006",
          amount: 100.01,
          creditor_name: "Creditor Name",
          creditor_iban: "DE88100900001234567892",
          creditor_bic: "BANKDEFF"
        })
        |> ExSepa.CreditTransfer.to_xml()

      assert xml =~ "<BICFI>BANKDEFF</BICFI>"
    end

    test "rejects unstructured debtor addresses" do
      assert_raise ExSepa.CreditTransfer.PaymentInformationError,
                   "unstructured addresses are not supported; address_lines require both town_name and country",
                   fn ->
                     ExSepa.CreditTransfer.new(%{
                       msg_id: "Msg-ID-007",
                       initiating_party_name: "Initiating Party"
                     })
                     |> ExSepa.CreditTransfer.add_payment_information(%{
                       payment_id: "Payment-ID-0007",
                       requested_execution_date: Date.utc_today(),
                       debtor_name: "Debtor Name",
                       debtor_iban: "DE87200500001234567890",
                       debtor_address: %{
                         address_lines: ["MUSTERSTRASSE 1", "10115 BERLIN"]
                       }
                     })
                   end
    end

    test "rejects unstructured creditor addresses" do
      assert_raise ExSepa.CreditTransfer.TransactionInformationError,
                   "unstructured addresses are not supported; address_lines require both town_name and country",
                   fn ->
                     ExSepa.CreditTransfer.new(%{
                       msg_id: "Msg-ID-008",
                       initiating_party_name: "Initiating Party"
                     })
                     |> ExSepa.CreditTransfer.add_payment_information(%{
                       payment_id: "Payment-ID-0008",
                       requested_execution_date: Date.utc_today(),
                       debtor_name: "Debtor Name",
                       debtor_iban: "DE87200500001234567890"
                     })
                     |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-0008", %{
                       end_to_end_id: "EndToEndId-0008",
                       amount: 100.01,
                       creditor_name: "Creditor Name",
                       creditor_iban: "DE88100900001234567892",
                       creditor_address: %{
                         address_lines: ["CITY HALL GROTE MARKT 1", "1000 BRUSSELS"]
                       }
                     })
                   end
    end

    test "skips payment information groups without transactions" do
      msg_id = example_msg_id()
      i_party = example_person_name()
      date = Date.utc_today()
      debtor_name = example_person_name()

      xml =
        ExSepa.CreditTransfer.new(%{msg_id: msg_id, initiating_party_name: i_party})
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Pmt-ID-001",
          requested_execution_date: date,
          debtor_name: debtor_name,
          debtor_iban: example_eea_iban()
        })
        |> ExSepa.CreditTransfer.add_payment_information(%{
          payment_id: "Pmt-ID-002",
          requested_execution_date: date,
          debtor_name: debtor_name,
          debtor_iban: example_eea_iban()
        })
        |> ExSepa.CreditTransfer.add_transaction_information("Pmt-ID-002", %{
          end_to_end_id: "EndToEndId-0001",
          amount: 100.01,
          creditor_name: "Creditor Name",
          creditor_iban: "DE88100900001234567892"
        })
        |> ExSepa.CreditTransfer.to_xml()

      assert length(Regex.scan(~r/<PmtInf>/, xml)) == 1
      assert xml =~ "<PmtInfId>Pmt-ID-002</PmtInfId>"
      refute xml =~ "<PmtInfId>Pmt-ID-001</PmtInfId>"
    end
  end

  describe "ExSepa.CreditTransfer.validate_xml/1" do
    test "validates SCT XML with the default schema" do
      xml = ExSepa.credit_transfer_example_one()

      assert ExSepa.CreditTransfer.validate_xml(xml) == xml
    end
  end

  describe "ExSepa.CreditTransfer.validate_xml/2" do
    test "validates SCT Inst XML with the scheme-specific schema" do
      xml = ExSepa.credit_transfer_instant_example_one()

      assert ExSepa.CreditTransfer.validate_xml(xml, :sct_inst) == xml
    end
  end
end
