defmodule ExSepa.CreditTransfer.TransactionInformation do
  alias ExSepa.Validation

  @moduledoc false
  # """
  # Credit Transfer Transaction Information: Provides information on the individual transaction(s) included in the message.
  # """

  @enforce_keys [:end_to_end_id, :amount, :creditor_name, :creditor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          end_to_end_id: String.t(),
          amount: float(),
          creditor_name: String.t(),
          creditor_address: ExSepa.Address.t() | nil,
          creditor_iban: String.t(),
          creditor_bic: String.t(),
          remittance_information: String.t()
        }

  defstruct [
    :end_to_end_id,
    :amount,
    :creditor_name,
    :creditor_address,
    :creditor_iban,
    creditor_bic: "",
    remittance_information: ""
  ]

  @doc false
  # """
  # Add Transaction Information: Provides information on the individual transaction included in the message.

  # The map has the following keys:

  #   * `:end_to_end_id` - The Originator's Reference of the Credit Transfer Instruction (maximum length of 35 characters).
  #   * `:amount` - The Amount of the Credit Transfer in euro.
  #   * `:creditor_name` - The Name of the Creditor / Beneficiary (maximum length of 70 characters).
  #   * `:creditor_iban` - The account number (IBAN) of the Creditor / Beneficiary.
  #   * `:creditor_bic` - OPTIONAL: BIC code of the Creditor PSP. Only mandatory when the Creditor PSP is located in a non-EEA SEPA country or territory. If empty, `CdtrAgt` is not used in the generated XML.
  #   * `:creditor_address` - OPTIONAL: Structured or hybrid address. Only mandatory when the Creditor PSP is located in a non-EEA SEPA country or territory. At least `:town_name` and `:country` must be used. `:address_lines` may additionally be used for up to two hybrid address lines. More details in `ExSepa.Address`.
  #   * `:remittance_information` - OPTIONAL: The Remittance Information sent by the Originator to the Beneficiary (maximum length of 140 characters). If empty, `RmtInf` is not used in the generated XML.
  # """
  @spec new(%{
          :end_to_end_id => String.t(),
          :amount => float(),
          :creditor_name => String.t(),
          :creditor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(transaction_information),
    do: build(__MODULE__, @enforce_keys, transaction_information)

  @doc false
  def build(module, enforce_keys, transaction_information) do
    case transaction_information do
      %{
        end_to_end_id: end_to_end_id,
        amount: amount,
        creditor_name: creditor_name,
        creditor_iban: creditor_iban
      }
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(creditor_name) and
             is_binary(creditor_iban) ->
        with {:ok, new_end_to_end_id} <- Validation.max_text(:end_to_end_id, end_to_end_id, 35),
             :ok <- Validation.amount(amount),
             {:ok, new_creditor_name} <- Validation.max_text(:creditor_name, creditor_name, 70),
             :ok <- Validation.iban(creditor_iban),
             {:ok, optional_data} <- get_optional_data(transaction_information),
             :ok <-
               Validation.address_mandatory(
                 String.slice(creditor_iban, 0, 2),
                 optional_data.creditor_bic,
                 optional_data.creditor_address
               ) do
          {:ok,
           struct(module, %{
             end_to_end_id: new_end_to_end_id,
             amount: amount,
             creditor_name: new_creditor_name,
             creditor_iban: creditor_iban,
             creditor_bic: optional_data.creditor_bic,
             creditor_address: optional_data.creditor_address,
             remittance_information: optional_data.remittance_information
           })}
        end

      %{
        end_to_end_id: end_to_end_id,
        amount: _amount,
        creditor_name: creditor_name,
        creditor_iban: creditor_iban
      }
      when is_binary(end_to_end_id) and is_binary(creditor_name) and is_binary(creditor_iban) ->
        {:error,
         "amount must be a positive number with up to 2 decimal places, e.g. 18.2 or 18.02"}

      _ ->
        missing_keys = enforce_keys -- Map.keys(transaction_information)

        if missing_keys == [] do
          with :ok <-
                 Validation.text(
                   [
                     {:end_to_end_id, transaction_information[:end_to_end_id]},
                     {:creditor_name, transaction_information[:creditor_name]},
                     {:creditor_iban, transaction_information[:creditor_iban]}
                   ],
                   "Parameters must be strings."
                 ) do
            {:error, "Something has gone wrong: #{transaction_information}"}
          end
        else
          {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
        end
    end
  end

  defp get_optional_data(transaction_information) do
    with {:ok, creditor_bic} <- get_creditor_bic(transaction_information),
         {:ok, remittance_information} <- get_remittance_information(transaction_information),
         {:ok, creditor_address} <-
           ExSepa.Address.get_address(transaction_information, :creditor_address),
         :ok <- Validation.bic(creditor_bic),
         {:ok, new_remittance_information} <-
           Validation.optional_max_text(:remittance_information, remittance_information, 140) do
      {:ok,
       %{
         creditor_bic: creditor_bic,
         creditor_address: creditor_address,
         remittance_information: new_remittance_information
       }}
    end
  end

  defp get_creditor_bic(transaction_information) do
    case Map.fetch(transaction_information, :creditor_bic) do
      {:ok, creditor_bic} when is_binary(creditor_bic) ->
        {:ok, creditor_bic}

      {:ok, creditor_bic} ->
        Validation.text([{:creditor_bic, creditor_bic}], "Parameters must be strings.")

      :error ->
        {:ok, ""}
    end
  end

  defp get_remittance_information(transaction_information) do
    case Map.fetch(transaction_information, :remittance_information) do
      {:ok, remittance_information} when is_binary(remittance_information) ->
        {:ok, remittance_information}

      {:ok, remittance_information} ->
        Validation.text(
          [{:remittance_information, remittance_information}],
          "Parameters must be strings."
        )

      :error ->
        {:ok, ""}
    end
  end
end

defmodule ExSepa.CreditTransfer.TransactionInformationError do
  @moduledoc false
  defexception [:message]
end

defmodule ExSepa.CreditTransferInstant.TransactionInformation do
  alias ExSepa.CreditTransfer.TransactionInformation, as: CreditTransferTransactionInformation

  @moduledoc false
  # """
  # Instant Credit Transfer Transaction Information: Instant-specific transaction data built on the shared credit transfer implementation.
  # """

  @enforce_keys [:end_to_end_id, :amount, :creditor_name, :creditor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          end_to_end_id: String.t(),
          amount: float(),
          creditor_name: String.t(),
          creditor_address: ExSepa.Address.t() | nil,
          creditor_iban: String.t(),
          creditor_bic: String.t(),
          remittance_information: String.t()
        }

  defstruct [
    :end_to_end_id,
    :amount,
    :creditor_name,
    :creditor_address,
    :creditor_iban,
    creditor_bic: "",
    remittance_information: ""
  ]

  @doc false
  # """
  # Add Transaction Information: Instant-specific transaction information backed by the shared credit transfer logic.

  # The map has the following keys:

  #   * `:end_to_end_id` - The Originator's Reference of the SCT Inst Instruction (maximum length of 35 characters).
  #   * `:amount` - The Amount of the SCT Inst in euro.
  #   * `:creditor_name` - The Name of the Creditor / Beneficiary (maximum length of 70 characters).
  #   * `:creditor_iban` - The account number (IBAN) of the Creditor / Beneficiary.
  #   * `:creditor_bic` - OPTIONAL: BIC code of the Creditor PSP. Only mandatory when the Creditor PSP is located in a non-EEA SEPA country or territory. If empty, `CdtrAgt` is not used in the generated XML.
  #   * `:creditor_address` - OPTIONAL: Structured or hybrid address. Only mandatory when the Creditor PSP is located in a non-EEA SEPA country or territory. At least `:town_name` and `:country` must be used. `:address_lines` may additionally be used for up to two hybrid address lines. More details in `ExSepa.Address`.
  #   * `:remittance_information` - OPTIONAL: The Remittance Information sent by the Originator to the Beneficiary (maximum length of 140 characters). If empty, `RmtInf` is not used in the generated XML.
  # """
  @spec new(%{
          :end_to_end_id => String.t(),
          :amount => float(),
          :creditor_name => String.t(),
          :creditor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(transaction_information),
    do:
      CreditTransferTransactionInformation.build(
        __MODULE__,
        @enforce_keys,
        transaction_information
      )
end

defmodule ExSepa.CreditTransferInstant.TransactionInformationError do
  @moduledoc false
  defexception [:message]
end
