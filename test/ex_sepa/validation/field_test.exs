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
end
