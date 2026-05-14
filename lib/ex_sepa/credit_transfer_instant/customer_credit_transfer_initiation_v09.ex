defmodule ExSepa.CreditTransferInstant.CustomerCreditTransferInitiationV09 do
  alias ExSepa.CreditTransfer.CustomerCreditTransferInitiationV09, as: CreditTransferXml

  @moduledoc false

  @doc false
  @spec to_xml(ExSepa.CreditTransferInstant.t()) :: String.t()
  def to_xml(%ExSepa.CreditTransferInstant{} = credit_transfer),
    do: CreditTransferXml.to_xml(credit_transfer, :sct_inst)
end
