defmodule ExSepa.Validation.Xml do
  @moduledoc false

  @spec validate(String.t(), String.t()) :: String.t()
  def validate(xml, xsd_path) do
    {:ok, xsddoc} = File.read(Path.expand(xsd_path))
    {:ok, model} = :erlsom.compile_xsd(xsddoc)

    case :erlsom.scan(xml, model) do
      {:ok, _out, _rest} ->
        xml

      {:error, [{:exception, {:error, message}}, _stack, _received]} ->
        raise ExSepa.Validation.XmlError, message: to_string(message)
    end
  end
end

defmodule ExSepa.Validation.XmlError do
  @moduledoc false
  defexception [:message]
end
