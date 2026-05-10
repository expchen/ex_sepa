defmodule ExSepa.CreditTransfer.Scheme do
  @moduledoc false

  @type t :: :sct | :sct_inst

  @spec service_level_code(t()) :: String.t()
  def service_level_code(_scheme), do: "SEPA"

  @spec local_instrument_code(t()) :: String.t() | nil
  def local_instrument_code(:sct), do: nil
  def local_instrument_code(_scheme), do: "INST"

  @spec instruction_priority_allowed?(t()) :: boolean()
  def instruction_priority_allowed?(:sct), do: false
  def instruction_priority_allowed?(_scheme), do: true

  @spec allows_datetime_requested_execution_date?(t()) :: boolean()
  def allows_datetime_requested_execution_date?(:sct), do: false
  def allows_datetime_requested_execution_date?(_scheme), do: true

  @spec validation_xsd(t()) :: String.t()
  def validation_xsd(_scheme), do: "priv/xsd/pain.001.001.09_GBIC_5.xsd"
end
