defmodule ExSepa.CreditTransfer.TransactionInformationTest do
  use ExUnit.Case, async: true
  import ExSepa.TestSupport.FactoryHelpers
  doctest ExSepa.CreditTransfer.TransactionInformation

  describe "ExSepa.CreditTransfer.TransactionInformation.new/1" do
    test "ok" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:ok,
                %ExSepa.CreditTransfer.TransactionInformation{
                  end_to_end_id: endtoendid,
                  amount: amount,
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_bic: "",
                  remittance_information: ""
                }}
    end

    test "with BIC - ok" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()
      creditor_bic = example_bic()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: creditor_bic
             }) ==
               {:ok,
                %ExSepa.CreditTransfer.TransactionInformation{
                  end_to_end_id: endtoendid,
                  amount: amount,
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_bic: creditor_bic,
                  remittance_information: ""
                }}
    end

    test "with BIC and remittance_information - ok" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()
      creditor_bic = example_bic()
      remittance_information = Faker.Beer.yeast()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: creditor_bic,
               remittance_information: remittance_information
             }) ==
               {:ok,
                %ExSepa.CreditTransfer.TransactionInformation{
                  end_to_end_id: endtoendid,
                  amount: amount,
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_bic: creditor_bic,
                  remittance_information: normalize_text(remittance_information)
                }}
    end

    test "with hybrid creditor address - ok" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      address_lines = [Faker.Address.street_address()]

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: "CH9300762011623852957",
               creditor_bic: "RAIFCH22005",
               creditor_address: %{
                 town_name: "Zurich",
                 country: "CH",
                 address_lines: address_lines
               }
             }) ==
               {:ok,
                %ExSepa.CreditTransfer.TransactionInformation{
                  end_to_end_id: endtoendid,
                  amount: amount,
                  creditor_name: creditor_name,
                  creditor_iban: "CH9300762011623852957",
                  creditor_bic: "RAIFCH22005",
                  creditor_address: %ExSepa.Schema.Address{
                    town_name: "Zurich",
                    country: "CH",
                    address_lines: address_lines
                  },
                  remittance_information: ""
                }}
    end

    test "fail: creditor_address is not a map" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_address: "Zurich"
             }) == {:error, "creditor_address: must be a map"}
    end

    test "remittance_information normalizes special characters" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()
      creditor_bic = example_bic()
      remittance_information = Faker.Beer.yeast()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: creditor_bic,
               remittance_information: "&" <> remittance_information
             }) ==
               {:ok,
                %ExSepa.CreditTransfer.TransactionInformation{
                  end_to_end_id: endtoendid,
                  amount: amount,
                  creditor_name: creditor_name,
                  creditor_address: nil,
                  creditor_iban: creditor_iban,
                  creditor_bic: creditor_bic,
                  remittance_information: normalize_text("&" <> remittance_information)
                }}
    end

    test "fail: end_to_end_id wrong type" do
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: 951_753,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error,
                "Parameters must be strings. - end_to_end_id: must be UTF-8 encoded binary"}
    end

    test "fail: end_to_end_id contains unsupported characters" do
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert match?(
               {:error, _},
               ExSepa.CreditTransfer.TransactionInformation.new(%{
                 end_to_end_id: Faker.Person.Hy.name(),
                 amount: amount,
                 creditor_name: creditor_name,
                 creditor_iban: creditor_iban
               })
             )
    end

    test "fail: end_to_end_id too long" do
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: Faker.Util.join(5, "-", &Faker.Gov.Us.ssn/0),
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "end_to_end_id: Maximum length of 35 characters"}
    end

    test "fail: amount wrong type" do
      endtoendid = example_end_to_end_id()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: Date.utc_today(),
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error,
                "amount must be a positive number with up to 2 decimal places, e.g. 18.2 or 18.02"}
    end

    test "fail: amount is integer zero" do
      endtoendid = example_end_to_end_id()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: 0,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error,
                "amount must be a positive number with up to 2 decimal places, e.g. 18.2 or 18.02"}
    end

    test "fail: amount is 0.0" do
      endtoendid = example_end_to_end_id()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: 0.0,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "The amount must be more then 0.00"}
    end

    test "fail: amount is negative" do
      endtoendid = example_end_to_end_id()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: -50.20,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "The amount must be more then 0.00"}
    end

    test "fail: amount is too high" do
      endtoendid = example_end_to_end_id()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: 1_999_999_999.00,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "The amount must be less then 999,999,999.99 euro"}
    end

    test "fail: amount has too many decimal places" do
      endtoendid = example_end_to_end_id()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: 50.2053,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "Amount has too many decimal places"}
    end

    test "fail: creditor_name UTF-8" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: 123_456_789,
               creditor_iban: creditor_iban
             }) ==
               {:error,
                "Parameters must be strings. - creditor_name: must be UTF-8 encoded binary"}
    end

    test "fail: creditor_name length" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()

      creditor_name =
        Faker.Util.join(20, " ", &Faker.Person.first_name/0) <> " " <> Faker.Person.name()

      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "creditor_name: Maximum length of 70 characters"}
    end

    test "fail: creditor_name must not begin with /" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: "/Creditor Name",
               creditor_iban: creditor_iban
             }) == {:error, "creditor_name: Text field must not begin with '/'"}
    end

    test "fail: creditor_name must not end with /" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: "Creditor Name/",
               creditor_iban: creditor_iban
             }) == {:error, "creditor_name: Text field must not end with '/'"}
    end

    test "fail: creditor_name must not contain //" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: "Creditor // Name",
               creditor_iban: creditor_iban
             }) == {:error, "creditor_name: Text field must not contain '//'"}
    end

    test "fail: creditor_iban invalid" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()

      assert match?(
               {:error, _},
               ExSepa.CreditTransfer.TransactionInformation.new(%{
                 end_to_end_id: endtoendid,
                 amount: amount,
                 creditor_name: creditor_name,
                 creditor_iban: "XX00INVALIDIBAN"
               })
             )
    end

    test "fail: creditor_iban wrong type" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: 123_456_789
             }) ==
               {:error,
                "Parameters must be strings. - creditor_iban: must be UTF-8 encoded binary"}
    end

    test "fail: creditor_bic invalid" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "Foo"
             }) ==
               {:error, "BIC is not valid"}
    end

    test "fail: creditor_bic wrong type" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: 123
             }) ==
               {:error,
                "Parameters must be strings. - creditor_bic: must be UTF-8 encoded binary"}
    end

    test "fail: remittance_information wrong type" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               remittance_information: 123
             }) ==
               {:error,
                "Parameters must be strings. - remittance_information: must be UTF-8 encoded binary"}
    end

    test "fail: remittance_information too long" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()
      creditor_name = example_person_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               remittance_information: Faker.Util.format("%141a")
             }) == {:error, "remittance_information: Maximum length of 140 characters"}
    end

    test "error: missing key :creditor_iban" do
      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: example_end_to_end_id(),
               amount: example_amount(),
               creditor_name: example_person_name()
             }) ==
               {:error, "missing keys: [:creditor_iban]"}
    end

    test "fail: non-EEA creditor requires BIC" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: "Swiss Creditor",
               creditor_iban: "CH9300762011623852957"
             }) == {:error, "BIC is mandatory for non-EEA SEPA country or territory"}
    end

    test "fail: non-EEA creditor requires address when BIC is present" do
      endtoendid = example_end_to_end_id()
      amount = example_amount()

      assert ExSepa.CreditTransfer.TransactionInformation.new(%{
               end_to_end_id: endtoendid,
               amount: amount,
               creditor_name: "Swiss Creditor",
               creditor_iban: "CH9300762011623852957",
               creditor_bic: "RAIFCH22005"
             }) == {:error, "Address is mandatory for non-EEA SEPA country or territory"}
    end
  end
end
