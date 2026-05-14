defmodule ExSepa.TestSupport.FactoryHelpers do
  import ExSepa.Validation.CountryCodes, only: [get_eea_iban_country_codes: 0]

  def example_msg_id, do: Faker.Gov.Us.ein()

  def example_payment_id, do: Faker.Gov.Us.ein()

  def example_end_to_end_id, do: Faker.Gov.Us.ssn()

  def example_person_name, do: Faker.Person.name() |> sanitize_text()

  def example_organisation_name, do: Faker.Team.name() |> sanitize_text()

  def example_eea_iban do
    Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))
  end

  def example_amount, do: Faker.Commerce.price()

  def example_bic, do: "BANKDEFFXXX"

  def example_mandate_id, do: Faker.Gov.Us.ein()

  def sanitize_text(text) do
    String.replace(text, ~r/[<>&']/, "")
  end

  def normalize_text(text) do
    text
    |> String.replace("ä", "a")
    |> String.replace("ö", "o")
    |> String.replace("ü", "u")
    |> String.replace("Ä", "a")
    |> String.replace("Ö", "o")
    |> String.replace("Ü", "u")
    |> String.replace("ß", "s")
    |> String.replace("&", "+")
    |> String.replace("*", ".")
    |> String.replace("$", ".")
    |> String.replace("%", ".")
  end
end
