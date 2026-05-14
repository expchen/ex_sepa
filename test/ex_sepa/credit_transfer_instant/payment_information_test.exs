defmodule ExSepa.CreditTransferInstant.PaymentInformationTest do
  use ExUnit.Case, async: true
  import ExSepa.Validation.CountryCodes, only: [get_eea_iban_country_codes: 0]
  import ExSepa.TestSupport.FactoryHelpers
  doctest ExSepa.CreditTransferInstant.PaymentInformation

  describe "ExSepa.CreditTransferInstant.PaymentInformation.new/1" do
    test "ok with Date" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) ==
               {:ok,
                %ExSepa.CreditTransferInstant.PaymentInformation{
                  payment_id: payment_id,
                  requested_execution_date: date,
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban
                }}
    end

    test "with BIC - ok" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban,
               debtor_bic: "BANKDEFFXXX"
             }) ==
               {:ok,
                %ExSepa.CreditTransferInstant.PaymentInformation{
                  payment_id: payment_id,
                  requested_execution_date: date,
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban,
                  debtor_bic: "BANKDEFFXXX"
                }}
    end

    test "ok with DateTime and instruction_priority atom" do
      payment_id = example_payment_id()
      date = DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.truncate(:second)
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               instruction_priority: :High,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) ==
               {:ok,
                %ExSepa.CreditTransferInstant.PaymentInformation{
                  payment_id: payment_id,
                  requested_execution_date: date,
                  instruction_priority: "HIGH",
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban
                }}
    end

    test "ok with instruction_priority string" do
      payment_id = example_payment_id()
      date = DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.truncate(:second)
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               instruction_priority: "NORM",
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) ==
               {:ok,
                %ExSepa.CreditTransferInstant.PaymentInformation{
                  payment_id: payment_id,
                  requested_execution_date: date,
                  instruction_priority: "NORM",
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban
                }}
    end

    test "debtor_name normalizes special characters" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = "Müller & Partner"
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) ==
               {:ok,
                %ExSepa.CreditTransferInstant.PaymentInformation{
                  payment_id: payment_id,
                  requested_execution_date: date,
                  debtor_name: normalize_text(debtor_name),
                  debtor_iban: debtor_iban
                }}
    end

    test "with address - ok" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      city = Faker.Address.city()
      country_codes = Enum.drop(get_eea_iban_country_codes(), -1)

      country =
        Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban,
               debtor_address: %{town_name: city, country: country}
             }) ==
               {:ok,
                %ExSepa.CreditTransferInstant.PaymentInformation{
                  payment_id: payment_id,
                  requested_execution_date: date,
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban,
                  debtor_address: %ExSepa.Schema.Address{town_name: city, country: country}
                }}
    end

    test "with hybrid address - ok" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      city = Faker.Address.city()
      country_codes = Enum.drop(get_eea_iban_country_codes(), -1)

      country =
        Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

      address_lines = [Faker.Address.street_address(), Faker.Address.secondary_address()]

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban,
               debtor_address: %{
                 town_name: city,
                 country: country,
                 address_lines: address_lines
               }
             }) ==
               {:ok,
                %ExSepa.CreditTransferInstant.PaymentInformation{
                  payment_id: payment_id,
                  requested_execution_date: date,
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban,
                  debtor_address: %ExSepa.Schema.Address{
                    town_name: city,
                    country: country,
                    address_lines: address_lines
                  }
                }}
    end

    test "with transaction_information list - ok" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      {:ok, transaction_information} =
        ExSepa.CreditTransferInstant.TransactionInformation.new(%{
          end_to_end_id: example_end_to_end_id(),
          amount: example_amount(),
          creditor_name: example_person_name(),
          creditor_iban: example_eea_iban()
        })

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban,
               transaction_information: [transaction_information]
             }) ==
               {:ok,
                %ExSepa.CreditTransferInstant.PaymentInformation{
                  payment_id: payment_id,
                  requested_execution_date: date,
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban,
                  transaction_information: [transaction_information]
                }}
    end

    test "fail: debtor_address is not a map" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban,
               debtor_address: "Berlin"
             }) == {:error, "debtor_address: must be a map"}
    end

    test "fail: payment_id too long" do
      payment_id = Faker.Util.format("%3A-ID-%#{Faker.random_between(35, 50)}d")
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) == {:error, "payment_id: Maximum length of 35 characters"}
    end

    test "fail: payment_id wrong type" do
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: 00_000_001,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) ==
               {:error, "Parameters must be strings. - payment_id: must be UTF-8 encoded binary"}
    end

    test "fail: requested_execution_date Date is in the past" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(-1)
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) == {:error, "The requested execution date must not be in the past."}
    end

    test "fail: requested_execution_date DateTime is in the past" do
      payment_id = example_payment_id()
      date = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.truncate(:second)
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) == {:error, "The requested execution date must not be in the past."}
    end

    test "fail: requested_execution_date is not a date or datetime" do
      payment_id = example_payment_id()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: "text",
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) == {:error, "Parameter requested_execution_date must be a date or datetime"}
    end

    test "fail: debtor_name too long" do
      payment_id = example_payment_id()
      date = Date.utc_today()

      debtor_name =
        Faker.Util.format(
          "%1A%#{Faker.random_between(34, 40)}a %1A%#{Faker.random_between(34, 40)}a"
        )

      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) == {:error, "debtor_name: Maximum length of 70 characters"}
    end

    test "fail: debtor_name wrong type" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: Date.utc_today(),
               debtor_iban: debtor_iban
             }) ==
               {:error, "Parameters must be strings. - debtor_name: must be UTF-8 encoded binary"}
    end

    test "fail: debtor_iban invalid" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = Faker.Util.format("%2A%2d%#{Faker.random_between(2, 40)}d")

      assert match?(
               {:error, _},
               ExSepa.CreditTransferInstant.PaymentInformation.new(%{
                 payment_id: payment_id,
                 requested_execution_date: date,
                 debtor_name: debtor_name,
                 debtor_iban: debtor_iban
               })
             )
    end

    test "fail: debtor_iban wrong type" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: 123_456_789
             }) ==
               {:error, "Parameters must be strings. - debtor_iban: must be UTF-8 encoded binary"}
    end

    test "fail: debtor_bic invalid" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban,
               debtor_bic: "Foo"
             }) ==
               {:error, "BIC is not valid"}
    end

    test "fail: debtor_bic wrong type" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban,
               debtor_bic: 123
             }) ==
               {:error, "Parameters must be strings. - debtor_bic: must be UTF-8 encoded binary"}
    end

    test "fail: instruction_priority invalid value" do
      payment_id = example_payment_id()
      date = DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.truncate(:second)
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               instruction_priority: :Foo,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) ==
               {:error,
                "instruction_priority: must be one of [:High, :Normal, \"HIGH\", \"NORM\"]"}
    end

    test "fail: instruction_priority wrong type" do
      payment_id = example_payment_id()
      date = DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.truncate(:second)
      debtor_name = example_person_name()
      debtor_iban = example_eea_iban()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               instruction_priority: 123,
               debtor_name: debtor_name,
               debtor_iban: debtor_iban
             }) ==
               {:error,
                "instruction_priority: must be one of [:High, :Normal, \"HIGH\", \"NORM\"]"}
    end

    test "error: missing key :debtor_iban" do
      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: example_payment_id(),
               requested_execution_date: Date.utc_today(),
               debtor_name: example_person_name()
             }) ==
               {:error, "missing keys: [:debtor_iban]"}
    end

    test "fail: non-EEA debtor requires BIC" do
      payment_id = example_payment_id()
      date = Date.utc_today()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: "Swiss Debtor",
               debtor_iban: "CH7280005000088877766"
             }) == {:error, "BIC is mandatory for non-EEA SEPA country or territory"}
    end

    test "fail: non-EEA debtor requires address when BIC is present" do
      payment_id = example_payment_id()
      date = Date.utc_today()

      assert ExSepa.CreditTransferInstant.PaymentInformation.new(%{
               payment_id: payment_id,
               requested_execution_date: date,
               debtor_name: "Swiss Debtor",
               debtor_iban: "CH7280005000088877766",
               debtor_bic: "RAIFCH22005"
             }) == {:error, "Address is mandatory for non-EEA SEPA country or territory"}
    end
  end
end
