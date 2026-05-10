defmodule ExSepa.CreditTransfer.PaymentInformation do
  alias ExSepa.CreditTransfer.Scheme
  alias ExSepa.FieldValidation

  @instruction_priorities %{High: "HIGH", Normal: "NORM"}

  @moduledoc false
  # """
  # Payment Information: Set of characteristics that apply to the debit side of the payment transactions included in the credit transfer transaction initiation.
  # """

  @enforce_keys [:payment_id, :requested_execution_date, :debtor_name, :debtor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          payment_id: String.t(),
          requested_execution_date: Date.t(),
          debtor_name: String.t(),
          debtor_address: ExSepa.Address.t() | nil,
          debtor_iban: String.t(),
          debtor_bic: String.t(),
          transaction_information: list(ExSepa.CreditTransfer.TransactionInformation.t()) | nil
        }

  defstruct [
    :payment_id,
    :requested_execution_date,
    :debtor_name,
    :debtor_address,
    :debtor_iban,
    debtor_bic: "",
    transaction_information: []
  ]

  @doc false
  # """
  # Add Payment Information: Set of characteristics that apply to the debit side of the payment transactions included in the credit transfer transaction initiation.

  # The map has the following keys:

  #   * `:payment_id` - Unique identification, as assigned by a sending party, to unambiguously identify the payment information group within the message (maximum length of 35 characters).
  #   * `:requested_execution_date` - The Requested Execution Date of the Credit Transfer instruction (ISODate). The date must be today or a future date.
  #   * `:debtor_name` - The Name of the Debtor / Originator (maximum length of 70 characters).
  #   * `:debtor_iban` - The account number (IBAN) of the Debtor / Originator.
  #   * `:debtor_bic` - OPTIONAL: BIC code of the Debtor PSP. Only mandatory when the Debtor PSP is located in a non-EEA SEPA country or territory.
  #   * `:debtor_address` - OPTIONAL: Structured or hybrid address. Only mandatory when the Debtor PSP is located in a non-EEA SEPA country or territory. At least `:town_name` and `:country` must be used. `:address_lines` may additionally be used for up to two hybrid address lines. More details in `ExSepa.Address`.
  # """
  @spec new(%{
          :payment_id => String.t(),
          :requested_execution_date => Date.t(),
          :debtor_name => String.t(),
          :debtor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(payment_information), do: build(:sct, __MODULE__, @enforce_keys, payment_information)

  @spec build(any(), any(), any(), map()) :: :ok | {:error, any()} | {:ok, struct()}
  @doc false
  def build(scheme, module, enforce_keys, transaction_information)

  def build(
        scheme,
        module,
        _enforce_keys,
        %{
          payment_id: payment_id,
          requested_execution_date: requested_execution_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = payment_information
      )
      when scheme in [:sct, :sct_inst] and
             is_binary(payment_id) and is_binary(debtor_name) and is_binary(debtor_iban) do
    if valid_requested_execution_date_type?(scheme, requested_execution_date) do
      with :ok <- validate_requested_execution_date(scheme, requested_execution_date),
           {:ok, new_payment_id} <- FieldValidation.max_text(:payment_id, payment_id, 35),
           {:ok, new_debtor_name} <- FieldValidation.max_text(:debtor_name, debtor_name, 70),
           :ok <- FieldValidation.iban(debtor_iban),
           {:ok, optional_data} <- get_optional_data(scheme, payment_information),
           :ok <-
             FieldValidation.address_mandatory(
               String.slice(debtor_iban, 0, 2),
               optional_data.debtor_bic,
               optional_data.debtor_address
             ) do
        attributes =
          %{
            payment_id: new_payment_id,
            requested_execution_date: requested_execution_date,
            debtor_name: new_debtor_name,
            debtor_iban: debtor_iban,
            debtor_bic: optional_data.debtor_bic,
            debtor_address: optional_data.debtor_address,
            transaction_information: optional_data.transaction_information
          }
          |> maybe_put_instruction_priority(scheme, optional_data)

        {:ok, struct(module, attributes)}
      end
    else
      {:error, requested_execution_date_type_error(scheme)}
    end
  end

  def build(_scheme, _module, enforce_keys, payment_information) do
    missing_keys = enforce_keys -- Map.keys(payment_information)

    if missing_keys == [] do
      with :ok <-
             FieldValidation.text(
               [
                 {:payment_id, payment_information[:payment_id]},
                 {:debtor_name, payment_information[:debtor_name]},
                 {:debtor_iban, payment_information[:debtor_iban]}
               ],
               "Parameters must be strings."
             ) do
        {:error, "Something has gone wrong: #{payment_information}"}
      end
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end

  @doc false
  @spec validate_requested_execution_date(Date.t()) :: :ok | {:error, String.t()}
  def validate_requested_execution_date(%Date{} = date),
    do: validate_requested_execution_date(:sct, date)

  @doc false
  def validate_requested_execution_date(:sct, %Date{} = date) do
    case Date.compare(date, Date.utc_today()) do
      :lt -> {:error, "The requested execution date must not be in the past."}
      _ -> :ok
    end
  end

  def validate_requested_execution_date(:sct_inst, %Date{} = date),
    do: validate_requested_execution_date(:sct, date)

  def validate_requested_execution_date(:sct_inst, %DateTime{} = datetime) do
    case DateTime.compare(datetime, DateTime.utc_now()) do
      :lt -> {:error, "The requested execution date must not be in the past."}
      _ -> :ok
    end
  end

  def validate_requested_execution_date(_scheme, _requested_execution_date),
    do: {:error, "unsupported requested execution date type"}

  @doc false
  def get_optional_data(payment_information), do: get_optional_data(:sct, payment_information)

  @doc false
  def get_optional_data(scheme, payment_information) do
    with {:ok, debtor_bic} <- get_debtor_bic(payment_information),
         {:ok, transaction_information} <- get_transaction_information(payment_information),
         {:ok, debtor_address} <-
           ExSepa.Address.get_address(payment_information, :debtor_address),
         {:ok, instruction_priority} <- get_instruction_priority(scheme, payment_information),
         :ok <- FieldValidation.bic(debtor_bic) do
      {:ok,
       %{
         instruction_priority: instruction_priority,
         debtor_bic: debtor_bic,
         debtor_address: debtor_address,
         transaction_information: transaction_information
       }}
    end
  end

  defp maybe_put_instruction_priority(attributes, scheme, optional_data) do
    if Scheme.instruction_priority_allowed?(scheme) do
      Map.put(attributes, :instruction_priority, optional_data.instruction_priority)
    else
      attributes
    end
  end

  defp get_debtor_bic(payment_information) do
    case Map.fetch(payment_information, :debtor_bic) do
      {:ok, debtor_bic} when is_binary(debtor_bic) ->
        {:ok, debtor_bic}

      {:ok, debtor_bic} ->
        FieldValidation.text([{:debtor_bic, debtor_bic}], "Parameters must be strings.")

      :error ->
        {:ok, ""}
    end
  end

  defp get_transaction_information(payment_information) do
    case Map.fetch(payment_information, :transaction_information) do
      {:ok, transaction_information} when is_list(transaction_information) ->
        {:ok, transaction_information}

      :error ->
        {:ok, []}
    end
  end

  defp get_instruction_priority(scheme, payment_information) do
    if Scheme.instruction_priority_allowed?(scheme) do
      case Map.fetch(payment_information, :instruction_priority) do
        {:ok, instruction_priority} when is_atom(instruction_priority) ->
          case Map.fetch(@instruction_priorities, instruction_priority) do
            {:ok, value} ->
              {:ok, value}

            :error ->
              {:error,
               "instruction_priority: must be one of [:High, :Normal, \"HIGH\", \"NORM\"]"}
          end

        {:ok, "HIGH"} ->
          {:ok, "HIGH"}

        {:ok, "NORM"} ->
          {:ok, "NORM"}

        {:ok, _instruction_priority} ->
          {:error, "instruction_priority: must be one of [:High, :Normal, \"HIGH\", \"NORM\"]"}

        :error ->
          {:ok, ""}
      end
    else
      {:ok, ""}
    end
  end

  defp valid_requested_execution_date_type?(_scheme, %Date{}), do: true

  defp valid_requested_execution_date_type?(scheme, %DateTime{}) do
    Scheme.allows_datetime_requested_execution_date?(scheme)
  end

  defp valid_requested_execution_date_type?(_scheme, _requested_execution_date), do: false

  defp requested_execution_date_type_error(scheme) do
    if Scheme.allows_datetime_requested_execution_date?(scheme) do
      "Parameter requested_execution_date must be a date or datetime"
    else
      "Parameter requested_execution_date must be a date"
    end
  end
end

defmodule ExSepa.CreditTransfer.PaymentInformationError do
  @moduledoc false
  defexception [:message]
end

defmodule ExSepa.CreditTransferInstant.PaymentInformation do
  alias ExSepa.CreditTransfer.PaymentInformation, as: CreditTransferPaymentInformation

  @moduledoc false
  # """
  # Instant Payment Information: SCT Inst-specific payment data built on the shared credit transfer implementation.
  # """

  @enforce_keys [:payment_id, :requested_execution_date, :debtor_name, :debtor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          payment_id: String.t(),
          requested_execution_date: Date.t() | DateTime.t(),
          instruction_priority: String.t(),
          debtor_name: String.t(),
          debtor_address: ExSepa.Address.t() | nil,
          debtor_iban: String.t(),
          debtor_bic: String.t(),
          transaction_information:
            list(ExSepa.CreditTransferInstant.TransactionInformation.t()) | nil
        }

  defstruct [
    :payment_id,
    :requested_execution_date,
    :debtor_name,
    :debtor_address,
    :debtor_iban,
    instruction_priority: "",
    debtor_bic: "",
    transaction_information: []
  ]

  @doc false
  # """
  # Add Payment Information: SCT Inst-specific payment information backed by the shared credit transfer logic.

  # The map has the following keys:

  #   * `:payment_id` - Unique identification, as assigned by a sending party, to unambiguously identify the payment information group within the message (maximum length of 35 characters).
  #   * `:requested_execution_date` - The Requested Execution Date of the SCT Inst instruction. A `Date` must be today or a future date. A `DateTime` must not be in the past.
  #   * `:instruction_priority` - OPTIONAL: Instruction priority for the SCT Inst instruction. Allowed values are `:High`, `:Normal`, `"HIGH"` and `"NORM"`.
  #   * `:debtor_name` - The Name of the Debtor / Originator (maximum length of 70 characters).
  #   * `:debtor_iban` - The account number (IBAN) of the Debtor / Originator.
  #   * `:debtor_bic` - OPTIONAL: BIC code of the Debtor PSP. Only mandatory when the Debtor PSP is located in a non-EEA SEPA country or territory.
  #   * `:debtor_address` - OPTIONAL: Structured or hybrid address. Only mandatory when the Debtor PSP is located in a non-EEA SEPA country or territory. At least `:town_name` and `:country` must be used. `:address_lines` may additionally be used for up to two hybrid address lines. More details in `ExSepa.Address`.
  # """
  @spec new(%{
          :payment_id => String.t(),
          :requested_execution_date => Date.t() | DateTime.t(),
          :debtor_name => String.t(),
          :debtor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(transaction_information),
    do:
      CreditTransferPaymentInformation.build(
        :sct_inst,
        __MODULE__,
        @enforce_keys,
        transaction_information
      )
end

defmodule ExSepa.CreditTransferInstant.PaymentInformationError do
  @moduledoc false
  defexception [:message]
end
