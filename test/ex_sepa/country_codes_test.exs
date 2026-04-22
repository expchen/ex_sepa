defmodule ExSepa.CountryCodesTest do
  use ExUnit.Case, async: true

  alias ExSepa.CountryCodes

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
end
