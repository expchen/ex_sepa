defmodule ExSepa.TestSupport.XmlHelpers do
  import ExUnit.Assertions

  def export_xml(xml, file_name) do
    export_dir = Path.expand("tmp/test_xml", File.cwd!())
    File.mkdir_p!(export_dir)
    path = Path.join(export_dir, file_name)
    File.write!(path, xml)
    path
  end

  def schema_validation_result(xml, schema_path) do
    {:ok, xsddoc} = File.read(Path.expand(schema_path))
    {:ok, model} = :erlsom.compile_xsd(xsddoc)

    :erlsom.scan(xml, model)
  end

  def validate_against_schema(xml, schema_path) do
    assert match?({:ok, _out, _rest}, schema_validation_result(xml, schema_path)), ":ok"
  end

  def validate_against_gbic_5_pain_001(xml) do
    validate_against_schema(xml, "priv/xsd/pain.001.001.09_GBIC_5.xsd")
  end

  def validate_against_gbic_5_pain_008(xml) do
    validate_against_schema(xml, "priv/xsd/pain.008.001.08_GBIC_5.xsd")
  end
end
