defmodule ExSepa.Validation.FieldTest do
  use ExUnit.Case, async: true
  doctest ExSepa.Validation.Field

  describe "ExSepa.Validation.Field.max_text/3" do
    test "normalizes EPC special characters" do
      assert ExSepa.Validation.Field.max_text(:creditor_name, "Müller & Co%*", 70) ==
               {:ok, "Muller + Co.."}
    end

    test "rejects text starting with slash" do
      assert ExSepa.Validation.Field.max_text(:debtor_name, "/Berlin", 70) ==
               {:error, "debtor_name: Text field must not begin with '/'"}
    end

    test "rejects text ending with slash" do
      assert ExSepa.Validation.Field.max_text(:debtor_name, "Berlin/", 70) ==
               {:error, "debtor_name: Text field must not end with '/'"}
    end

    test "rejects text containing double slash" do
      assert ExSepa.Validation.Field.max_text(:debtor_name, "Berlin // Mitte", 70) ==
               {:error, "debtor_name: Text field must not contain '//'"}
    end
  end

  describe "ExSepa.Validation.Field.bic/1" do
    test "accepts 8-character and 11-character BICs" do
      assert ExSepa.Validation.Field.bic("BANKDEFF") == :ok
      assert ExSepa.Validation.Field.bic("BANKDEFFXXX") == :ok
    end
  end

  describe "ExSepa.Validation.Field.address_mandatory/3" do
    test "passes for EEA debtor without bic or address" do
      assert ExSepa.Validation.Field.address_mandatory("DE", "", nil) == :ok
    end

    test "requires bic for non-EEA" do
      assert ExSepa.Validation.Field.address_mandatory("AD", "", nil) ==
               {:error, "BIC is mandatory for non-EEA SEPA country or territory"}
    end

    test "requires address for non-EEA when bic is present" do
      assert ExSepa.Validation.Field.address_mandatory("AD", "CASBADADXXX", nil) ==
               {:error, "Address is mandatory for non-EEA SEPA country or territory"}
    end
  end

  describe "ExSepa.Validation.Field.country_code/1" do
    test "keeps the current SEPA-specific behavior" do
      assert ExSepa.Validation.Field.country_code("DE") == :ok
      assert ExSepa.Validation.Field.country_code("US") == {:error, "Country code not in list!"}
    end
  end

  describe "ExSepa.Validation.Field.iso_country_code/1" do
    test "accepts ISO country codes beyond the SEPA lists" do
      assert ExSepa.Validation.Field.iso_country_code("DE") == :ok
      assert ExSepa.Validation.Field.iso_country_code("US") == :ok
      assert ExSepa.Validation.Field.iso_country_code("TW") == :ok
    end

    test "rejects invalid ISO country code formats and values" do
      assert ExSepa.Validation.Field.iso_country_code("us") ==
               {:error, "These characters are not part of the pattern test: us"}

      assert ExSepa.Validation.Field.iso_country_code("USA") ==
               {:error, "These characters are not part of the pattern test: A"}

      assert ExSepa.Validation.Field.iso_country_code("ZZ") ==
               {:error, "Country code not in ISO list!"}
    end
  end

  describe "ExSepa.Validation.Field.international_text/3" do
    test "accepts broader UTF-8 input without SEPA transliteration" do
      assert ExSepa.Validation.Field.international_text(:creditor_name, "Łukasz García", 70) ==
               {:ok, "Łukasz García"}
    end

    test "trims surrounding whitespace but keeps international characters" do
      assert ExSepa.Validation.Field.international_text(:creditor_name, "  José Álvarez  ", 70) ==
               {:ok, "José Álvarez"}
    end

    test "keeps the existing slash formatting rules" do
      assert ExSepa.Validation.Field.international_text(:creditor_name, "/任天堂", 70) ==
               {:error, "creditor_name: Text field must not begin with '/'"}
    end

    test "rejects invalid UTF-8 binaries" do
      assert ExSepa.Validation.Field.international_text(:creditor_name, <<0xFFFF::16>>, 70) ==
               {:error, "creditor_name: must be UTF-8 encoded binary"}
    end
  end

  describe "ExSepa.Validation.Field.optional_international_text/3" do
    test "accepts blank input" do
      assert ExSepa.Validation.Field.optional_international_text(:creditor_name, "   ", 70) ==
               {:ok, ""}
    end
  end

  describe "ExSepa.Validation.Field.creditor_identifier/1" do
    test "accepts a valid EPC creditor identifier" do
      assert ExSepa.Validation.Field.creditor_identifier("DE98ZZZ09999999999") ==
               {:ok, "DE98ZZZ09999999999"}
    end

    test "accepts a valid non-EEA EPC creditor identifier" do
      assert ExSepa.Validation.Field.creditor_identifier("CH10ZZZ00099999999") ==
               {:ok, "CH10ZZZ00099999999"}
    end

    test "rejects invalid creditor identifier check digits" do
      assert ExSepa.Validation.Field.creditor_identifier("DE00ZZZ09999999999") ==
               {:error, "creditor_id: invalid creditor identifier check digits"}
    end
  end

end
