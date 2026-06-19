defmodule ExSepa.DirectDebitTest do
  use ExUnit.Case, async: true
  import ExSepa.Validation.CountryCodes, only: [get_eea_iban_country_codes: 0]
  import ExSepa.TestSupport.FactoryHelpers
  import ExSepa.TestSupport.XmlHelpers
  doctest ExSepa.DirectDebit

  @creditor_id "DE98ZZZ09999999999"
  @non_eea_creditor_id "CH10ZZZ00099999999"
  @creditor_bic "BANKDEFFXXX"
  @end_to_end_id "EndToEndId-0001"
  @mandate_id "Mandate-Id-01"
  @mandate_signing_date ~D[2021-01-21]
  @remittance_information "Unstructured Remittance Information"
  @non_eea_debtor_name "Debtor Name"
  @non_eea_debtor_iban "CH7280005000088877766"
  @non_eea_debtor_bic "RAIFCH22005"
  @non_eea_debtor_address %{town_name: "Bern", country: "CH"}

  # Message setup and group header validation
  describe "ExSepa.DirectDebit.new/1" do
    test "Generate a new direct debit" do
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()

      assert ExSepa.DirectDebit.new(%{
               msg_id: msg_id,
               initiating_party_name: initiating_party_name
             }) ==
               %ExSepa.DirectDebit{
                 group_header: %ExSepa.Schema.GroupHeader{
                   msg_id: msg_id,
                   initiating_party_name: initiating_party_name
                 },
                 payment_information: nil
               }
    end

    test "Generate a new direct debit - fail: msg_id is not a String" do
      assert_raise ExSepa.Schema.GroupHeaderError, "msg_id: must be UTF-8 encoded binary", fn ->
        ExSepa.DirectDebit.new(%{
          msg_id: <<0xFFFF::16>>,
          initiating_party_name: example_person_name()
        })
      end
    end

    test "Generate a new direct debit - fail: initiating_party_name is not a String" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: example_msg_id(),
                       initiating_party_name: <<0xFFFF::16>>
                     })
                   end
    end

    test "Generate a new direct debit - fail on msg_id" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "Parameters must be strings. - msg_id: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: 000_001,
                       initiating_party_name: example_person_name()
                     })
                   end
    end

    test "Generate a new direct debit - fail on initiating_party_name" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "Parameters must be strings. - initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: example_msg_id(),
                       initiating_party_name: 345
                     })
                   end
    end

    test "Generate a new direct debit - fail on msg_id and initiating_party_name" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "Parameters must be strings. - msg_id: must be UTF-8 encoded binary - initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: 00450,
                       initiating_party_name: 123_456
                     })
                   end
    end

    test "Generate a new direct debit - fail: on msg_id length" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "msg_id: Maximum length of 35 characters",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: "0123456789012345678901234567890123456789",
                       initiating_party_name: example_person_name()
                     })
                   end
    end

    test "Generate a new direct debit - fail: on initiating_party_name length" do
      assert_raise ExSepa.Schema.GroupHeaderError,
                   "initiating_party_name: Maximum length of 70 characters",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: example_msg_id(),
                       initiating_party_name:
                         "The name of the person who has initiated the call is too long to be entered in this field."
                     })
                   end
    end
  end

  # Payment block orchestration, including duplicates and collection metadata.
  describe "ExSepa.DirectDebit.add_payment_information/2" do
    test "Generate a new Payment Information - :ok" do
      date = Date.utc_today() |> Date.add(5)
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })

      assert ExSepa.DirectDebit.add_payment_information(
               direct_debit,
               %{
                 payment_id: payment_id,
                 due_date: date,
                 creditor_id: @creditor_id,
                 creditor_name: creditor_name,
                 creditor_iban: creditor_iban,
                 creditor_bic: @creditor_bic
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: msg_id,
                 initiating_party_name: initiating_party_name
               },
               payment_information: [
                 %ExSepa.DirectDebit.PaymentInformation{
                   payment_id: payment_id,
                   due_date: date,
                   creditor_id: @creditor_id,
                   creditor_name: creditor_name,
                   creditor_iban: creditor_iban,
                   creditor_bic: @creditor_bic
                 }
               ]
             }
    end

    test "Generate a second new Payment Information - :ok" do
      date = Date.utc_today() |> Date.add(5)
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      payment_id_two = example_payment_id()
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })

      assert direct_debit
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: @creditor_id,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             })
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: payment_id_two,
               due_date: date |> Date.add(2),
               creditor_id: @creditor_id,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == %ExSepa.DirectDebit{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: msg_id,
                 initiating_party_name: initiating_party_name
               },
               payment_information: [
                 %ExSepa.DirectDebit.PaymentInformation{
                   payment_id: payment_id_two,
                   due_date: date |> Date.add(2),
                   creditor_id: @creditor_id,
                   creditor_name: creditor_name,
                   creditor_iban: creditor_iban
                 },
                 %ExSepa.DirectDebit.PaymentInformation{
                   payment_id: payment_id,
                   due_date: date,
                   creditor_id: @creditor_id,
                   creditor_name: creditor_name,
                   creditor_iban: creditor_iban
                 }
               ]
             }
    end

    test "Generate a second new Payment Information - fail: same payment_id" do
      date = Date.utc_today() |> Date.add(5)
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })

      assert_raise ExSepa.DirectDebit.PaymentInformationError,
                   "payment_id: #{payment_id} already exists",
                   fn ->
                     direct_debit
                     |> ExSepa.DirectDebit.add_payment_information(%{
                       payment_id: payment_id,
                       due_date: date,
                       creditor_id: @creditor_id,
                       creditor_name: creditor_name,
                       creditor_iban: creditor_iban
                     })
                     |> ExSepa.DirectDebit.add_payment_information(%{
                       payment_id: payment_id,
                       due_date: date,
                       creditor_id: @creditor_id,
                       creditor_name: creditor_name,
                       creditor_iban: creditor_iban
                     })
                   end
    end
  end

  # Transaction collection orchestration, mandate data, and routing into the right payment block.
  describe "ExSepa.DirectDebit.add_transaction_information/3" do
    test "Generate a new Transaction Information - :ok" do
      date = Date.utc_today() |> Date.add(3)
      msg_id = example_msg_id()
      initiating_party_name = example_person_name()
      payment_id = example_payment_id()
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: msg_id,
          initiating_party_name: initiating_party_name
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: payment_id,
            due_date: date,
            creditor_id: @non_eea_creditor_id,
            creditor_name: creditor_name,
            creditor_iban: creditor_iban,
            creditor_bic: @creditor_bic
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               payment_id,
               %{
                 end_to_end_id: @end_to_end_id,
                 amount: 100.01,
                 mandate_id: @mandate_id,
                 mandate_signing_date: @mandate_signing_date,
                 debtor_name: @non_eea_debtor_name,
                 debtor_address: @non_eea_debtor_address,
                 debtor_iban: @non_eea_debtor_iban,
                 debtor_bic: @non_eea_debtor_bic,
                 remittance_information: @remittance_information
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: msg_id,
                 initiating_party_name: initiating_party_name
               },
               payment_information: [
                 %ExSepa.DirectDebit.PaymentInformation{
                   payment_id: payment_id,
                   due_date: date,
                   creditor_id: @non_eea_creditor_id,
                   creditor_name: creditor_name,
                   creditor_iban: creditor_iban,
                   creditor_bic: @creditor_bic,
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.DirectDebit.TransactionInformation{
                       end_to_end_id: @end_to_end_id,
                       amount: 100.01,
                       mandate_id: @mandate_id,
                       mandate_signing_date: @mandate_signing_date,
                       debtor_name: @non_eea_debtor_name,
                       debtor_address: %ExSepa.Schema.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: @non_eea_debtor_iban,
                       debtor_bic: @non_eea_debtor_bic,
                       remittance_information: @remittance_information
                     }
                   ]
                 }
               ]
             }
    end

    test "accepts a valid non-EEA creditor identifier" do
      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001-CH",
          initiating_party_name: "Initiating Party"
        })

      assert ExSepa.DirectDebit.add_payment_information(
               direct_debit,
               %{
                 payment_id: "Pmt-ID-001-CH",
                 due_date: Date.utc_today() |> Date.add(3),
                 creditor_id: @non_eea_creditor_id,
                 creditor_name: "Creditor Name",
                 creditor_iban: "DE87200500001234567890"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: "Msg-ID-001-CH",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.DirectDebit.PaymentInformation{
                   payment_id: "Pmt-ID-001-CH",
                   due_date: Date.utc_today() |> Date.add(3),
                   creditor_id: @non_eea_creditor_id,
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890"
                 }
               ]
             }
    end

    test "error: BIC is mandatory" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "DE98ZZZ09999999999",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      assert_raise ExSepa.DirectDebit.TransactionInformationError,
                   "BIC is mandatory for non-EEA SEPA country or territory",
                   fn ->
                     ExSepa.DirectDebit.add_transaction_information(
                       direct_debit,
                       "Pmt-ID-001",
                       %{
                         end_to_end_id: "EndToEndId-0001",
                         amount: 100.01,
                         mandate_id: "Mandate-Id-01",
                         mandate_signing_date: ~D[2021-01-21],
                         debtor_name: "Debtor Name",
                         debtor_address: %{town_name: "Bern", country: "CH"},
                         debtor_iban: "CH7280005000088877766",
                         remittance_information: "Unstructured Remittance Information"
                       }
                     )
                   end
    end

    test "Generate a new Transaction Information 3" do
      date = Date.utc_today() |> Date.add(3)

      dd =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: "Pmt-ID-001",
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: "Creditor Name",
               creditor_iban: "DE87200500001234567890",
               creditor_bic: "BANKDEFFXXX"
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               "Pmt-ID-001",
               %{
                 end_to_end_id: "EndToEndId-0001",
                 amount: 100.01,
                 mandate_id: "Mandate-Id-01",
                 mandate_signing_date: ~D[2021-01-21],
                 debtor_name: "Debtor Name",
                 debtor_address: %{town_name: "Bern", country: "CH"},
                 debtor_iban: "CH7280005000088877766",
                 debtor_bic: "RAIFCH22005",
                 remittance_information: "Unstructured Remittance Information"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: "Msg-ID-001",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.DirectDebit.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "DE98ZZZ09999999999",
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890",
                   creditor_bic: "BANKDEFFXXX",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.DirectDebit.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Schema.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "Generate a new Transaction Information 4" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "DE98ZZZ09999999999",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
               %{
                 end_to_end_id: "EndToEndId-0001",
                 amount: 100.01,
                 mandate_id: "Mandate-Id-01",
                 mandate_signing_date: ~D[2021-01-21],
                 debtor_name: "Debtor Name",
                 debtor_address: %{town_name: "Bern", country: "CH"},
                 debtor_iban: "CH7280005000088877766",
                 debtor_bic: "RAIFCH22005",
                 remittance_information: "Unstructured Remittance Information"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.Schema.GroupHeader{
                 msg_id: "Msg-ID-001",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.DirectDebit.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "DE98ZZZ09999999999",
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890",
                   creditor_bic: "",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.DirectDebit.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Schema.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "Generate two Payment Information with two Transaction Informations" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "DE98ZZZ09999999999",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-002",
            due_date: date |> Date.add(1),
            creditor_id: "DE98ZZZ09999999999",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      direct_debit =
        ExSepa.DirectDebit.add_transaction_information(
          direct_debit,
          "Pmt-ID-001",
          %{
            end_to_end_id: "EndToEndId-0001",
            amount: 100.01,
            mandate_id: "Mandate-Id-01",
            mandate_signing_date: ~D[2021-01-21],
            debtor_name: "Debtor Name",
            debtor_address: %{town_name: "Bern", country: "CH"},
            debtor_iban: "CH7280005000088877766",
            debtor_bic: "RAIFCH22005",
            remittance_information: "Unstructured Remittance Information"
          }
        )

      direct_debit =
        ExSepa.DirectDebit.add_transaction_information(
          direct_debit,
          "Pmt-ID-002",
          %{
            end_to_end_id: "EndToEndId-0001",
            amount: 100.01,
            mandate_id: "Mandate-Id-01",
            mandate_signing_date: ~D[2021-01-21],
            debtor_name: "Debtor Name",
            debtor_address: %{town_name: "Bern", country: "CH"},
            debtor_iban: "CH7280005000088877766",
            debtor_bic: "RAIFCH22005",
            remittance_information: "Unstructured Remittance Information"
          }
        )

      direct_debit =
        ExSepa.DirectDebit.add_transaction_information(
          direct_debit,
          "Pmt-ID-001",
          %{
            end_to_end_id: "EndToEndId-0002",
            amount: 22.22,
            mandate_id: "Mandate-Id-02",
            mandate_signing_date: ~D[2022-02-22],
            debtor_name: "Debtor Name",
            debtor_address: %{town_name: "Bern", country: "CH"},
            debtor_iban: "CH7280005000088877766",
            debtor_bic: "RAIFCH22005",
            remittance_information: "Unstructured Remittance Information"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-002",
               %{
                 end_to_end_id: "EndToEndId-0002",
                 amount: 22.22,
                 mandate_id: "Mandate-Id-02",
                 mandate_signing_date: ~D[2022-02-22],
                 debtor_name: "Debtor Name",
                 debtor_address: %{town_name: "Bern", country: "CH"},
                 debtor_iban: "CH7280005000088877766",
                 debtor_bic: "RAIFCH22005",
                 remittance_information: "Unstructured Remittance Information"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.Schema.GroupHeader{
                 initiating_party_name: "Initiating Party",
                 msg_id: "Msg-ID-001"
               },
               payment_information: [
                 %ExSepa.DirectDebit.PaymentInformation{
                   creditor_address: nil,
                   creditor_bic: "",
                   creditor_iban: "DE87200500001234567890",
                   creditor_id: "DE98ZZZ09999999999",
                   creditor_name: "Creditor Name",
                   due_date: date |> Date.add(1),
                   payment_id: "Pmt-ID-002",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.DirectDebit.TransactionInformation{
                       end_to_end_id: "EndToEndId-0002",
                       amount: 22.22,
                       mandate_id: "Mandate-Id-02",
                       mandate_signing_date: ~D[2022-02-22],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Schema.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     },
                     %ExSepa.DirectDebit.TransactionInformation{
                       amount: 100.01,
                       debtor_address: %ExSepa.Schema.Address{
                         building_name: nil,
                         building_number: nil,
                         country: "CH",
                         country_sub_division: nil,
                         department: nil,
                         district_name: nil,
                         floor: nil,
                         post_box: nil,
                         post_code: nil,
                         room: nil,
                         street_name: nil,
                         sub_department: nil,
                         town_location_name: nil,
                         town_name: "Bern"
                       },
                       debtor_bic: "RAIFCH22005",
                       debtor_iban: "CH7280005000088877766",
                       debtor_name: "Debtor Name",
                       end_to_end_id: "EndToEndId-0001",
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 },
                 %ExSepa.DirectDebit.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "DE98ZZZ09999999999",
                   creditor_name: "Creditor Name",
                   creditor_address: nil,
                   creditor_iban: "DE87200500001234567890",
                   creditor_bic: "",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.DirectDebit.TransactionInformation{
                       end_to_end_id: "EndToEndId-0002",
                       amount: 22.22,
                       mandate_id: "Mandate-Id-02",
                       mandate_signing_date: ~D[2022-02-22],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Schema.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     },
                     %ExSepa.DirectDebit.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Schema.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "Generate a second Transaction Information - fail: no such payment_id" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "DE98ZZZ09999999999",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      assert_raise ExSepa.DirectDebit.TransactionInformationError,
                   "payment_id: Pmt-ID-002 does not exists in payment information",
                   fn ->
                     ExSepa.DirectDebit.add_transaction_information(
                       direct_debit,
                       "Pmt-ID-002",
                       %{
                         end_to_end_id: "EndToEndId-0001",
                         amount: 100.01,
                         mandate_id: "Mandate-Id-01",
                         mandate_signing_date: ~D[2021-01-21],
                         debtor_name: "Debtor Name",
                         debtor_iban: "CH7280005000088877766",
                         debtor_bic: "RAIFCH22005",
                         remittance_information: "Unstructured Remittance Information"
                       }
                     )
                   end
    end
  end

  # End-to-end XML generation, CORE sequence markers, and GBIC schema conformance.
  describe "ExSepa.DirectDebit.to_xml/1" do
    # XML integration tests assert DD-specific fixed values and structures while leaving
    # full-schema conformance to the GBIC_5 validation step.
    test "Generate XML without BIC" do
      msg_id = example_msg_id()
      i_party = example_person_name()

      pmt_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      end_to_end_id = Faker.Gov.Us.ssn()
      price = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      dd = ExSepa.DirectDebit.new(%{msg_id: msg_id, initiating_party_name: i_party})

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: pmt_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               pmt_id,
               %{
                 end_to_end_id: end_to_end_id,
                 amount: price,
                 mandate_id: mndt_id,
                 mandate_signing_date: mndt_date,
                 debtor_name: debtor_name,
                 debtor_iban: debtor_iban,
                 remittance_information: @remittance_information
               }
             )
             |> ExSepa.DirectDebit.to_xml() ==
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd\">\n  <CstmrDrctDbtInitn>\n    <GrpHdr>\n      <MsgId>#{msg_id}</MsgId>\n      <CreDtTm>#{DateTime.to_iso8601(DateTime.utc_now(:second))}</CreDtTm>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <InitgPty>\n        <Nm>#{i_party}</Nm>\n      </InitgPty>\n    </GrpHdr>\n    <PmtInf>\n      <PmtInfId>#{pmt_id}</PmtInfId>\n      <PmtMtd>DD</PmtMtd>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <PmtTpInf>\n        <SvcLvl>\n          <Cd>SEPA</Cd>\n        </SvcLvl>\n        <LclInstrm>\n          <Cd>CORE</Cd>\n        </LclInstrm>\n        <SeqTp>OOFF</SeqTp>\n      </PmtTpInf>\n      <ReqdColltnDt>#{date}</ReqdColltnDt>\n      <Cdtr>\n        <Nm>#{creditor_name}</Nm>\n      </Cdtr>\n      <CdtrAcct>\n        <Id>\n          <IBAN>#{creditor_iban}</IBAN>\n        </Id>\n      </CdtrAcct>\n      <CdtrAgt>\n        <FinInstnId>\n          <Othr>\n            <Id>NOTPROVIDED</Id>\n          </Othr>\n        </FinInstnId>\n      </CdtrAgt>\n      <ChrgBr>SLEV</ChrgBr>\n      <CdtrSchmeId>\n        <Id>\n          <PrvtId>\n            <Othr>\n              <Id>DE98ZZZ09999999999</Id>\n              <SchmeNm>\n                <Prtry>SEPA</Prtry>\n              </SchmeNm>\n            </Othr>\n          </PrvtId>\n        </Id>\n      </CdtrSchmeId>\n      <DrctDbtTxInf>\n        <PmtId>\n          <EndToEndId>#{end_to_end_id}</EndToEndId>\n        </PmtId>\n        <InstdAmt Ccy=\"EUR\">#{price}</InstdAmt>\n        <DrctDbtTx>\n          <MndtRltdInf>\n            <MndtId>#{mndt_id}</MndtId>\n            <DtOfSgntr>#{mndt_date}</DtOfSgntr>\n          </MndtRltdInf>\n        </DrctDbtTx>\n        <DbtrAgt>\n          <FinInstnId>\n            <Othr>\n              <Id>NOTPROVIDED</Id>\n            </Othr>\n          </FinInstnId>\n        </DbtrAgt>\n        <Dbtr>\n          <Nm>#{debtor_name}</Nm>\n        </Dbtr>\n        <DbtrAcct>\n          <Id>\n            <IBAN>#{debtor_iban}</IBAN>\n          </Id>\n        </DbtrAcct>\n        <RmtInf>\n          <Ustrd>#{@remittance_information}</Ustrd>\n        </RmtInf>\n      </DrctDbtTxInf>\n    </PmtInf>\n  </CstmrDrctDbtInitn>\n</Document>"
    end

    test "Generate XML with BIC" do
      msg_id = example_msg_id()
      i_party = example_person_name()

      pmt_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      end_to_end_id = Faker.Gov.Us.ssn()
      price = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      dd = ExSepa.DirectDebit.new(%{msg_id: msg_id, initiating_party_name: i_party})

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: pmt_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "BANKDEFFXXX"
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               pmt_id,
               %{
                 end_to_end_id: end_to_end_id,
                 amount: price,
                 mandate_id: mndt_id,
                 mandate_signing_date: mndt_date,
                 debtor_name: debtor_name,
                 debtor_iban: debtor_iban,
                 debtor_bic: "RAIFCH22005",
                 remittance_information: @remittance_information
               }
             )
             |> ExSepa.DirectDebit.to_xml() ==
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd\">\n  <CstmrDrctDbtInitn>\n    <GrpHdr>\n      <MsgId>#{msg_id}</MsgId>\n      <CreDtTm>#{DateTime.to_iso8601(DateTime.utc_now(:second))}</CreDtTm>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <InitgPty>\n        <Nm>#{i_party}</Nm>\n      </InitgPty>\n    </GrpHdr>\n    <PmtInf>\n      <PmtInfId>#{pmt_id}</PmtInfId>\n      <PmtMtd>DD</PmtMtd>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <PmtTpInf>\n        <SvcLvl>\n          <Cd>SEPA</Cd>\n        </SvcLvl>\n        <LclInstrm>\n          <Cd>CORE</Cd>\n        </LclInstrm>\n        <SeqTp>OOFF</SeqTp>\n      </PmtTpInf>\n      <ReqdColltnDt>#{date}</ReqdColltnDt>\n      <Cdtr>\n        <Nm>#{creditor_name}</Nm>\n      </Cdtr>\n      <CdtrAcct>\n        <Id>\n          <IBAN>#{creditor_iban}</IBAN>\n        </Id>\n      </CdtrAcct>\n      <CdtrAgt>\n        <FinInstnId>\n          <BICFI>BANKDEFFXXX</BICFI>\n        </FinInstnId>\n      </CdtrAgt>\n      <ChrgBr>SLEV</ChrgBr>\n      <CdtrSchmeId>\n        <Id>\n          <PrvtId>\n            <Othr>\n              <Id>DE98ZZZ09999999999</Id>\n              <SchmeNm>\n                <Prtry>SEPA</Prtry>\n              </SchmeNm>\n            </Othr>\n          </PrvtId>\n        </Id>\n      </CdtrSchmeId>\n      <DrctDbtTxInf>\n        <PmtId>\n          <EndToEndId>#{end_to_end_id}</EndToEndId>\n        </PmtId>\n        <InstdAmt Ccy=\"EUR\">#{price}</InstdAmt>\n        <DrctDbtTx>\n          <MndtRltdInf>\n            <MndtId>#{mndt_id}</MndtId>\n            <DtOfSgntr>#{mndt_date}</DtOfSgntr>\n          </MndtRltdInf>\n        </DrctDbtTx>\n        <DbtrAgt>\n          <FinInstnId>\n            <BICFI>RAIFCH22005</BICFI>\n          </FinInstnId>\n        </DbtrAgt>\n        <Dbtr>\n          <Nm>#{debtor_name}</Nm>\n        </Dbtr>\n        <DbtrAcct>\n          <Id>\n            <IBAN>#{debtor_iban}</IBAN>\n          </Id>\n        </DbtrAcct>\n        <RmtInf>\n          <Ustrd>#{@remittance_information}</Ustrd>\n        </RmtInf>\n      </DrctDbtTxInf>\n    </PmtInf>\n  </CstmrDrctDbtInitn>\n</Document>"
    end

    test "Generate XML with prebuilt transaction_information list" do
      msg_id = Faker.Gov.Us.ein()
      i_party = Faker.Person.name()

      pmt_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      x = 0
      # 1 Einzeltransaktionen benötigen ca. 55,3 ms
      # 10 Einzeltransaktionen benötigen ca. 71,3 ms
      # 100 Einzeltransaktionen benötigen ca. 0,2 s
      # 500 Einzeltransaktionen benötigen ca. 0,6 s
      # 1.000 Einzeltransaktionen benötigen ca. 1,4 s
      # 2.000 Einzeltransaktionen benötigen ca. 3,5 s
      # 3.000 Einzeltransaktionen benötigen ca. 5,4 s
      # 4.000 Einzeltransaktionen benötigen ca. 6,5 s
      # 5.000 Einzeltransaktionen benötigen ca. 7,6 s
      # 10.000 Einzeltransaktionen benötigen ca. 17 s
      # 20.000 Einzeltransaktionen benötigen ca. 43 s
      # 30.000 Einzeltransaktionen benötigen ca. 1 min. und 21 s
      # 40.000 Einzeltransaktionen benötigen ca. 1 min. und 55 s
      # 50.000 Einzeltransaktionen benötigen ca. 2 min. und 33 s
      # 100.000 Einzeltransaktionen benötigen ca. 7 min. und 51 s
      trans_infos =
        for n <- 0..x do
          end_to_end_id = Faker.Gov.Us.ssn()
          price = Faker.Commerce.price()
          mndt_id = Faker.Gov.Us.ein()
          mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
          debtor_name = Faker.Person.name()
          debtor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

          {:ok, ti} =
            ExSepa.DirectDebit.TransactionInformation.new(%{
              end_to_end_id: end_to_end_id,
              amount: price,
              mandate_id: mndt_id,
              mandate_signing_date: mndt_date,
              debtor_name: debtor_name,
              debtor_iban: debtor_iban,
              remittance_information: "Unstructured Remittance Information #{n}"
            })

          ti
        end

      direct_debit =
        ExSepa.DirectDebit.new(%{msg_id: msg_id, initiating_party_name: i_party})

      xml =
        direct_debit
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: pmt_id,
          due_date: date,
          creditor_id: "DE98ZZZ09999999999",
          creditor_name: creditor_name,
          creditor_iban: creditor_iban,
          transaction_information: trans_infos
        })
        |> ExSepa.DirectDebit.to_xml()

      assert File.exists?(export_xml(xml, "pain.dd.prebuilt_transactions.test.xml"))
    end

    test "skips payment information groups without transactions" do
      date = Date.utc_today() |> Date.add(3)

      xml =
        %{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        }
        |> ExSepa.DirectDebit.new()
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Pmt-ID-001",
          due_date: date,
          creditor_id: "DE98ZZZ09999999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        })
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Pmt-ID-002",
          due_date: date |> Date.add(1),
          creditor_id: "DE98ZZZ09999999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        })
        |> ExSepa.DirectDebit.add_transaction_information("Pmt-ID-002", %{
          end_to_end_id: "EndToEndId-0001",
          amount: 100.01,
          mandate_id: "Mandate-Id-01",
          mandate_signing_date: ~D[2021-01-21],
          debtor_name: "Debtor Name",
          debtor_iban: "CH7280005000088877766",
          debtor_bic: "RAIFCH22005",
          debtor_address: %{town_name: "Bern", country: "CH"}
        })
        |> ExSepa.DirectDebit.to_xml()

      assert length(Regex.scan(~r/<PmtInf>/, xml)) == 1
      assert xml =~ "<PmtInfId>Pmt-ID-002</PmtInfId>"
      refute xml =~ "<PmtInfId>Pmt-ID-001</PmtInfId>"
    end

    test "Generate XML 4" do
      direct_debit =
        ExSepa.DirectDebit.new(%{msg_id: "Msg-ID-003", initiating_party_name: "Initiating Party"})

      xml =
        direct_debit
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Payment-ID-0003",
          due_date: Date.utc_today() |> Date.add(5),
          creditor_id: "DE98ZZZ09999999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        })
        |> ExSepa.DirectDebit.add_transaction_information(
          "Payment-ID-0003",
          %{
            end_to_end_id: "EndToEndId-0003",
            amount: 100.01,
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

      assert File.exists?(export_xml(xml, "pain.dd.schema.test.xml"))

      validate_against_gbic_5_pain_008(xml)
    end

    test "Generate XML with 8-character BICs" do
      xml =
        %{msg_id: "Msg-ID-004", initiating_party_name: "Initiating Party"}
        |> ExSepa.DirectDebit.new()
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Payment-ID-0004",
          due_date: ~D[2026-11-14],
          creditor_id: "DE98ZZZ09999999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890",
          creditor_bic: "BANKDEFF"
        })
        |> ExSepa.DirectDebit.add_transaction_information(
          "Payment-ID-0004",
          %{
            end_to_end_id: "EndToEndId-0004",
            amount: 100.01,
            mandate_id: "Mandate-Id-04",
            mandate_signing_date: ~D[2024-04-24],
            debtor_name: "Debtor Name",
            debtor_iban: "AD6510434606G73BA76MI9TE",
            debtor_bic: "CASBADAD",
            debtor_address: %{town_name: "Andorra la Vella", country: "AD"}
          }
        )
        |> ExSepa.DirectDebit.to_xml()

      assert xml =~ "<BICFI>BANKDEFF</BICFI>"
      assert xml =~ "<BICFI>CASBADAD</BICFI>"
      validate_against_gbic_5_pain_008(xml)
    end

    test "Generate XML without remittance information omits RmtInf and stays schema-valid" do
      xml =
        %{
          msg_id: "Msg-ID-004B",
          initiating_party_name: "Initiating Party"
        }
        |> ExSepa.DirectDebit.new()
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Payment-ID-0004B",
          due_date: Date.utc_today() |> Date.add(5),
          creditor_id: @creditor_id,
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        })
        |> ExSepa.DirectDebit.add_transaction_information(
          "Payment-ID-0004B",
          %{
            end_to_end_id: "EndToEndId-0004B",
            amount: 100.01,
            mandate_id: "Mandate-Id-04B",
            mandate_signing_date: ~D[2024-04-24],
            debtor_name: "Debtor Name",
            debtor_iban: "DE88100900001234567892"
          }
        )
        |> ExSepa.DirectDebit.to_xml()

      refute xml =~ "<RmtInf>"
      validate_against_gbic_5_pain_008(xml)
    end

    test "Generate XML with hybrid address lines" do
      xml =
        %{msg_id: "Msg-ID-005", initiating_party_name: "Initiating Party"}
        |> ExSepa.DirectDebit.new()
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Payment-ID-0005",
          due_date: Date.utc_today() |> Date.add(5),
          creditor_id: "DE98ZZZ09999999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        })
        |> ExSepa.DirectDebit.add_transaction_information(
          "Payment-ID-0005",
          %{
            end_to_end_id: "EndToEndId-0005",
            amount: 100.01,
            mandate_id: "Mandate-Id-05",
            mandate_signing_date: ~D[2024-05-25],
            debtor_name: "Debtor Name",
            debtor_iban: "AD6510434606G73BA76MI9TE",
            debtor_bic: "CASBADADXXX",
            debtor_address: %{
              town_name: "Andorra la Vella",
              country: "AD",
              address_lines: ["Carrer de la Vall 1", "Edifici Central"]
            }
          }
        )
        |> ExSepa.DirectDebit.to_xml()

      assert xml =~ "<TwnNm>Andorra la Vella</TwnNm>"
      assert xml =~ "<Ctry>AD</Ctry>"
      assert xml =~ "<AdrLine>Carrer de la Vall 1</AdrLine>"
      assert xml =~ "<AdrLine>Edifici Central</AdrLine>"
      validate_against_gbic_5_pain_008(xml)
    end

    test "rejects unstructured debtor addresses" do
      assert_raise ExSepa.DirectDebit.TransactionInformationError,
                   "unstructured addresses are not supported; address_lines require both town_name and country",
                   fn ->
                     %{
                       msg_id: "Msg-ID-007",
                       initiating_party_name: "Initiating Party"
                     }
                     |> ExSepa.DirectDebit.new()
                     |> ExSepa.DirectDebit.add_payment_information(%{
                       payment_id: "Payment-ID-0007",
                       due_date: Date.utc_today() |> Date.add(5),
                       creditor_id: "DE98ZZZ09999999999",
                       creditor_name: "Creditor Name",
                       creditor_iban: "DE87200500001234567890"
                     })
                     |> ExSepa.DirectDebit.add_transaction_information(
                       "Payment-ID-0007",
                       %{
                         end_to_end_id: "EndToEndId-0007",
                         amount: 100.01,
                         mandate_id: "Mandate-Id-07",
                         mandate_signing_date: ~D[2024-07-27],
                         debtor_name: "Debtor Name",
                         debtor_iban: "DE88100900001234567892",
                         debtor_address: %{
                           address_lines: ["MUSTERSTRASSE 1", "10115 BERLIN"]
                         }
                       }
                     )
                   end
    end

    test "rejects unstructured creditor addresses" do
      assert_raise ExSepa.DirectDebit.PaymentInformationError,
                   "unstructured addresses are not supported; address_lines require both town_name and country",
                   fn ->
                     %{
                       msg_id: "Msg-ID-008",
                       initiating_party_name: "Initiating Party"
                     }
                     |> ExSepa.DirectDebit.new()
                     |> ExSepa.DirectDebit.add_payment_information(%{
                       payment_id: "Payment-ID-0008",
                       due_date: Date.utc_today() |> Date.add(5),
                       creditor_id: "DE98ZZZ09999999999",
                       creditor_name: "Creditor Name",
                       creditor_iban: "DE87200500001234567890",
                       creditor_address: %{
                         address_lines: ["MUSTERSTRASSE 1", "10115 BERLIN"]
                       }
                     })
                   end
    end
  end
end
