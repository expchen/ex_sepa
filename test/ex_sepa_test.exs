defmodule ExSepaTest do
  use ExUnit.Case, async: true

  describe "example generators" do
    test "generate direct debit XML examples" do
      assert ExSepa.direct_debit_example_one() =~ "<CstmrDrctDbtInitn>"
      assert ExSepa.direct_debit_example_two() =~ "<CstmrDrctDbtInitn>"
      assert ExSepa.direct_debit_example_three() =~ "<CstmrDrctDbtInitn>"
    end

    test "generate credit transfer XML examples" do
      assert ExSepa.credit_transfer_example_one() =~ "<CstmrCdtTrfInitn>"
      assert ExSepa.credit_transfer_example_two() =~ "<CstmrCdtTrfInitn>"
      assert ExSepa.credit_transfer_example_three() =~ "<CstmrCdtTrfInitn>"
    end

    test "generate instant credit transfer XML examples" do
      assert ExSepa.credit_transfer_instant_example_one() =~ "<CstmrCdtTrfInitn>"
      assert ExSepa.credit_transfer_instant_example_two() =~ "<CstmrCdtTrfInitn>"
      assert ExSepa.credit_transfer_instant_example_three() =~ "<CstmrCdtTrfInitn>"
    end
  end
end
