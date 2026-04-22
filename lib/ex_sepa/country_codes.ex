defmodule ExSepa.CountryCodes do
  @moduledoc false

  @doc false
  def get_eea_iban_country_codes(),
    do: [
      "AT",
      "BE",
      "BG",
      "CY",
      "CZ",
      "DE",
      "DK",
      "EE",
      "ES",
      "FI",
      "FR",
      "GR",
      "HU",
      "HR",
      "IE",
      "IS",
      "LI",
      "LT",
      "LU",
      "LV",
      "NL",
      "MT",
      "NO",
      "IT",
      "PL",
      "PT",
      "RO",
      "SE",
      "SK",
      "SI"
    ]

  @doc false
  def get_non_eea_iban_country_codes(),
    do: [
      "AD",
      "CH",
      "GB",
      "MC",
      "SM",
      # Vatican City State not in Faker iban list
      "VA"
    ]

  @doc false
  # """
  # List with IBAN country codes used in IBANs according to ISO 3166
  # """
  def get_iban_country_codes(),
    do: Enum.concat(get_eea_iban_country_codes(), get_non_eea_iban_country_codes())

  @doc false
  def get_eea_bic_country_codes(),
    do: [
      "AT",
      "BE",
      "BG",
      "BL",
      "CY",
      "CZ",
      "DE",
      "DK",
      "EE",
      "ES",
      "FI",
      "FR",
      "GF",
      "GP",
      "GR",
      "HU",
      "HR",
      "IE",
      "IS",
      "LI",
      "LT",
      "LU",
      "LV",
      "NL",
      "MF",
      "MT",
      "MQ",
      "NO",
      "IT",
      "PL",
      "PT",
      "RE",
      "RO",
      "SE",
      "SK",
      "SI",
      "YT"
    ]

  @doc false
  def get_non_eea_bic_country_codes(),
    do: [
      "AD",
      "CH",
      "GB",
      "GG",
      "IM",
      "JE",
      "MC",
      "PM",
      "SM",
      # Vatican City State not in Faker iban list
      "VA"
    ]

  @doc false
  # """
  # List with BIC country codes used in BICs according to ISO 3166
  # """
  def get_bic_country_codes(),
    do: Enum.concat(get_eea_bic_country_codes(), get_non_eea_bic_country_codes())
end
