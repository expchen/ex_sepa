defmodule ExSepa.Validation.CountryCodesTest do
  use ExUnit.Case, async: true

  alias ExSepa.Validation.CountryCodes

  describe "IBAN country codes" do
    test "combines EEA and non-EEA country codes" do
      assert CountryCodes.get_iban_country_codes() ==
               CountryCodes.get_eea_iban_country_codes() ++
                 CountryCodes.get_non_eea_iban_country_codes()
    end
  end

  describe "BIC country codes" do
    test "combines EEA and non-EEA country codes" do
      assert CountryCodes.get_bic_country_codes() ==
               CountryCodes.get_eea_bic_country_codes() ++
                 CountryCodes.get_non_eea_bic_country_codes()
    end
  end

  describe "ISO country codes" do
    test "include the existing SEPA-related country codes" do
      iso_country_codes = CountryCodes.get_iso_country_codes()

      assert Enum.all?(
               CountryCodes.get_iban_country_codes(),
               &Enum.member?(iso_country_codes, &1)
             )

      assert Enum.all?(CountryCodes.get_bic_country_codes(), &Enum.member?(iso_country_codes, &1))
    end

    test "allow broader non-SEPA country codes without changing SEPA lists" do
      assert CountryCodes.valid_iso_country_code?("US")
      assert CountryCodes.valid_iso_country_code?("CN")
      refute Enum.member?(CountryCodes.get_bic_country_codes(), "US")
      refute Enum.member?(CountryCodes.get_iban_country_codes(), "US")
    end

    test "reject invalid codes" do
      refute CountryCodes.valid_iso_country_code?("us")
      refute CountryCodes.valid_iso_country_code?("USA")
      refute CountryCodes.valid_iso_country_code?(nil)
    end
  end
end
