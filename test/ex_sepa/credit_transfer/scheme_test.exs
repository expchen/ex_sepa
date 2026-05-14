defmodule ExSepa.CreditTransfer.SchemeTest do
  use ExUnit.Case, async: true

  alias ExSepa.CreditTransfer.Scheme

  describe "local_instrument_code/1" do
    test "returns nil for SCT and INST for SCT Inst" do
      assert Scheme.local_instrument_code(:sct) == nil
      assert Scheme.local_instrument_code(:sct_inst) == "INST"
    end
  end

  describe "instruction_priority_allowed?/1" do
    test "returns false for SCT and true for SCT Inst" do
      refute Scheme.instruction_priority_allowed?(:sct)
      assert Scheme.instruction_priority_allowed?(:sct_inst)
    end
  end

  describe "allows_datetime_requested_execution_date?/1" do
    test "returns false for SCT and true for SCT Inst" do
      refute Scheme.allows_datetime_requested_execution_date?(:sct)
      assert Scheme.allows_datetime_requested_execution_date?(:sct_inst)
    end
  end

  describe "validation_xsd/1" do
    test "returns the pain.001 schema path for both schemes" do
      assert Scheme.validation_xsd(:sct) == "priv/xsd/pain.001.001.09_GBIC_5.xsd"
      assert Scheme.validation_xsd(:sct_inst) == "priv/xsd/pain.001.001.09_GBIC_5.xsd"
    end
  end
end
