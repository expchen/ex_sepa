defmodule ExSepa.DirectDebit.PaymentInformationTest do
  use ExUnit.Case, async: true
  import ExSepa.Validation.CountryCodes, only: [get_eea_iban_country_codes: 0]
  import ExSepa.TestSupport.FactoryHelpers
  doctest ExSepa.DirectDebit.PaymentInformation

  describe "ExSepa.DirectDebit.PaymentInformation.new/1" do
    test "ok" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:ok,
                %ExSepa.DirectDebit.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "DE98ZZZ09999999999",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban
                }}
    end

    test "with BIC - ok" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "BANKDEFFXXX"
             }) ==
               {:ok,
                %ExSepa.DirectDebit.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "DE98ZZZ09999999999",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_bic: "BANKDEFFXXX"
                }}
    end

    test "accepts a valid non-EEA creditor_id" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CH10ZZZ00099999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:ok,
                %ExSepa.DirectDebit.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "CH10ZZZ00099999999",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban
                }}
    end

    test "accepts lowercase creditor_id because the EPC format is case insensitive" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "de98zzz09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:ok,
                %ExSepa.DirectDebit.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "de98zzz09999999999",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban
                }}
    end

    test "creditor_name normalizes special characters" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = "Müller & Partner"
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:ok,
                %ExSepa.DirectDebit.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "DE98ZZZ09999999999",
                  creditor_name: normalize_text(creditor_name),
                  creditor_iban: creditor_iban
                }}
    end

    test "with BIC and sequence_type - ok" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "BANKDEFFXXX",
               sequence_type: :First
             }) ==
               {:ok,
                %ExSepa.DirectDebit.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "DE98ZZZ09999999999",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_bic: "BANKDEFFXXX",
                  sequence_type: :First
                }}
    end

    test "with address - ok" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      city = Faker.Address.city()
      country_codes = Enum.drop(get_eea_iban_country_codes(), -1)

      country =
        Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_address: %{town_name: city, country: country}
             }) ==
               {:ok,
                %ExSepa.DirectDebit.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "DE98ZZZ09999999999",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_address: %ExSepa.Schema.Address{town_name: city, country: country}
                }}
    end

    test "with hybrid address - ok" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      city = Faker.Address.city()
      country_codes = Enum.drop(get_eea_iban_country_codes(), -1)

      country =
        Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

      address_lines = [Faker.Address.street_address(), Faker.Address.secondary_address()]

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_address: %{
                 town_name: city,
                 country: country,
                 address_lines: address_lines
               }
             }) ==
               {:ok,
                %ExSepa.DirectDebit.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "DE98ZZZ09999999999",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_address: %ExSepa.Schema.Address{
                    town_name: city,
                    country: country,
                    address_lines: address_lines
                  }
                }}
    end

    test "fail: creditor_address is not a map" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_address: "Berlin"
             }) == {:error, "creditor_address: must be a map"}
    end

    test "fail: payment_id too long" do
      payment_id = Faker.Util.format("%3A-ID-%#{Faker.random_between(35, 50)}d")
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "payment_id: Maximum length of 35 characters"}
    end

    test "fail: payment_id wrong type" do
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: 00_000_001,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "Parameters must be strings. - payment_id: must be UTF-8 encoded binary"}
    end

    test "fail: due_date is not in the future" do
      payment_id = example_payment_id()
      date = Date.utc_today()
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "The due date must be in the future."}
    end

    test "fail: due_date is not a date" do
      payment_id = example_payment_id()
      date = "text"
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "Parameter due_date must be a date"}
    end

    test "fail: creditor_id too long" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_id = Faker.Util.format("%3AZZZ%#{Faker.random_between(35, 50)}d")
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: creditor_id,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "creditor_id: Maximum length of 35 characters"}
    end

    test "fail: creditor_id invalid checksum" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE00ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "creditor_id: invalid creditor identifier check digits"}
    end

    test "fail: creditor_id business code cannot contain spaces" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98Z Z09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "creditor_id: invalid creditor identifier structure"}
    end

    test "fail: creditor_id wrong type" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: 00_000_001,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "Parameters must be strings. - creditor_id: must be UTF-8 encoded binary"}
    end

    test "fail: creditor_name too long" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)

      creditor_name =
        Faker.Util.format(
          "%1A%#{Faker.random_between(34, 40)}a %1A%#{Faker.random_between(34, 40)}a"
        )

      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "creditor_name: Maximum length of 70 characters"}
    end

    test "fail: creditor_name wrong type" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Date.utc_today() |> Date.add(3)
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error,
                "Parameters must be strings. - creditor_name: must be UTF-8 encoded binary"}
    end

    test "fail: creditor_iban invalid" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Util.format("%2A%2d%#{Faker.random_between(2, 40)}d")

      # could be {:error, :invalid_country} or {:error, :invalid_length}
      assert match?(
               {:error, _},
               ExSepa.DirectDebit.PaymentInformation.new(%{
                 payment_id: payment_id,
                 due_date: date,
                 creditor_id: "DE98ZZZ09999999999",
                 creditor_name: creditor_name,
                 creditor_iban: creditor_iban
               })
             )
    end

    test "fail: creditor_iban wrong type" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: 123_456_789
             }) ==
               {:error,
                "Parameters must be strings. - creditor_iban: must be UTF-8 encoded binary"}
    end

    test "fail: creditor_bic invalid" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "Foo"
             }) ==
               {:error, "BIC is not valid"}
    end

    test "fail: creditor_bic wrong type" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: 123
             }) ==
               {:error,
                "Parameters must be strings. - creditor_bic: must be UTF-8 encoded binary"}
    end

    test "fail: sequence_type invalid value" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               sequence_type: :Foo
             }) ==
               {:error,
                "Parameter sequence_type must be an atom :OneOff, :First, :Recurring, :Final"}
    end

    test "fail: sequence_type wrong type" do
      payment_id = example_payment_id()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = example_organisation_name()
      creditor_iban = example_eea_iban()

      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               sequence_type: "Foo"
             }) ==
               {:error,
                "Parameter sequence_type must be an atom :OneOff, :First, :Recurring, :Final"}
    end

    test "error: missing key :creditor_iban" do
      assert ExSepa.DirectDebit.PaymentInformation.new(%{
               payment_id: example_payment_id(),
               due_date: Date.utc_today() |> Date.add(3),
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: example_organisation_name()
             }) ==
               {:error, "missing keys: [:creditor_iban]"}
    end
  end
end
