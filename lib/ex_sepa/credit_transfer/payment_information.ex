defmodule ExSepa.CreditTransfer.PaymentInformation do
  alias ExSepa.CreditTransfer.Scheme
  alias ExSepa.Validation.Field, as: FieldValidation

  @instruction_priorities %{High: "HIGH", Normal: "NORM"}

  @moduledoc """
  Public payment information model for SEPA credit transfer batches.

  Each payment information block groups transactions that share the same debtor
  and requested execution date.

  ## Required Fields

    * `:payment_id` - unique identifier for the payment information block
    * `:requested_execution_date` - execution date for the batch
    * `:debtor_name` - debtor/originator name
    * `:debtor_iban` - debtor/originator IBAN

  Optional debtor BIC, debtor address, and prebuilt transaction information
  entries may also be provided.
  """

  @enforce_keys [:payment_id, :requested_execution_date, :debtor_name, :debtor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          payment_id: String.t(),
          requested_execution_date: Date.t(),
          debtor_name: String.t(),
          debtor_address: ExSepa.Schema.Address.t() | nil,
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

  @doc """
  Validates input and builds a credit transfer payment information struct.

  Required keys are `:payment_id`, `:requested_execution_date`, `:debtor_name`,
  and `:debtor_iban`.

  The requested execution date must be today or later. Optional
  `:debtor_bic`, `:debtor_address`, and prebuilt `:transaction_information`
  entries may also be provided.

  ## Example

      iex> ExSepa.CreditTransfer.PaymentInformation.new(%{
      ...>   payment_id: "Payment-ID-0001",
      ...>   requested_execution_date: Date.utc_today(),
      ...>   debtor_name: "Example GmbH",
      ...>   debtor_iban: "DE87200500001234567890"
      ...> })
      {:ok,
       %ExSepa.CreditTransfer.PaymentInformation{
         payment_id: "Payment-ID-0001",
         requested_execution_date: Date.utc_today(),
         debtor_name: "Example GmbH",
         debtor_address: nil,
         debtor_iban: "DE87200500001234567890",
         debtor_bic: "",
         transaction_information: []
       }}
  """
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
         {:ok, transaction_information} <-
           get_transaction_information(scheme, payment_information),
         {:ok, debtor_address} <-
           ExSepa.Schema.Address.get_address(payment_information, :debtor_address),
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

  defp get_transaction_information(scheme, payment_information) do
    case Map.fetch(payment_information, :transaction_information) do
      {:ok, transaction_information} when is_list(transaction_information) ->
        validate_transaction_information_list(scheme, transaction_information)

      :error ->
        {:ok, []}

      {:ok, _transaction_information} ->
        {:error, "transaction_information: must be a list"}
    end
  end

  defp validate_transaction_information_list(_scheme, []), do: {:ok, []}

  defp validate_transaction_information_list(scheme, transaction_information) do
    expected_module = transaction_information_module(scheme)

    Enum.reduce_while(
      Enum.with_index(transaction_information),
      {:ok, transaction_information},
      fn {entry, index}, _acc ->
        if match?(%{__struct__: ^expected_module}, entry) do
          {:cont, {:ok, transaction_information}}
        else
          {:halt,
           {:error,
            "transaction_information[#{index}]: must be a #{inspect(expected_module)} struct"}}
        end
      end
    )
  end

  defp transaction_information_module(:sct),
    do: ExSepa.CreditTransfer.TransactionInformation

  defp transaction_information_module(:sct_inst),
    do: ExSepa.CreditTransferInstant.TransactionInformation

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
