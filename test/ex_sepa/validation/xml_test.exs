defmodule ExSepa.Validation.XmlTest do
  use ExUnit.Case, async: true

  alias ExSepa.Validation.Xml
  alias ExSepa.Validation.XmlError

  describe "validate/2" do
    test "returns the original XML when it matches the schema" do
      xml = ExSepa.credit_transfer_example_one()

      assert Xml.validate(xml, "priv/xsd/pain.001.001.09_GBIC_5.xsd") == xml
    end

    test "raises XmlError when the XML does not match the schema" do
      bad_xml = "<Document></Document>"

      assert_raise XmlError, fn ->
        Xml.validate(bad_xml, "priv/xsd/pain.001.001.09_GBIC_5.xsd")
      end
    end
  end
end
