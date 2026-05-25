defmodule ExSepa.DirectDebit.PaymentInformation do
  alias ExSepa.Validation.Field, as: FieldValidation

  @moduledoc """
  Public payment information model for SEPA direct debit batches.

  Each payment information block groups collections that share the same creditor,
  due date, and sequence type.

  ## Required Fields

    * `:payment_id` - unique identifier for the payment information block
    * `:due_date` - collection due date
    * `:creditor_id` - SEPA creditor identifier
    * `:creditor_name` - creditor name
    * `:creditor_iban` - creditor IBAN

  Optional creditor BIC, creditor address, sequence type, and prebuilt
  transaction information entries may also be provided.
  """

  @type sequence_type3_code_atom :: :OneOff | :First | :Recurring | :Final
  @sequence_type3_code_atom [:OneOff, :First, :Recurring, :Final]
  @sequence_type3_code %{OneOff: "OOFF", First: "FRST", Recurring: "RCUR", Final: "FNAL"}

  @enforce_keys [:payment_id, :due_date, :creditor_id, :creditor_name, :creditor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          payment_id: String.t(),
          due_date: Date.t(),
          creditor_id: String.t(),
          creditor_name: String.t(),
          creditor_address: ExSepa.Schema.Address.t() | nil,
          creditor_iban: String.t(),
          creditor_bic: String.t(),
          sequence_type: sequence_type3_code_atom(),
          transaction_information: list(ExSepa.DirectDebit.TransactionInformation.t()) | nil
        }

  defstruct [
    :payment_id,
    :due_date,
    :creditor_id,
    :creditor_name,
    :creditor_address,
    :creditor_iban,
    creditor_bic: "",
    sequence_type: :OneOff,
    transaction_information: []
  ]

  @doc """
  Validates input and builds a direct debit payment information struct.

  Required keys are `:payment_id`, `:due_date`, `:creditor_id`,
  `:creditor_name`, and `:creditor_iban`.

  Optional `:creditor_bic`, `:creditor_address`, `:sequence_type`, and prebuilt
  `:transaction_information` entries may also be provided. Accepted
  `:sequence_type` values are `:OneOff`, `:First`, `:Recurring`, and `:Final`.
  If omitted, `:sequence_type` defaults to `:OneOff`.

  ## Example

      iex> ExSepa.DirectDebit.PaymentInformation.new(%{
      ...>   payment_id: "Payment-ID-0001",
      ...>   due_date: Date.utc_today() |> Date.add(5),
      ...>   creditor_id: "DE98ZZZ09999999999",
      ...>   creditor_name: "Example Club",
      ...>   creditor_iban: "DE87200500001234567890"
      ...> })
      {:ok,
       %ExSepa.DirectDebit.PaymentInformation{
         payment_id: "Payment-ID-0001",
         due_date: Date.utc_today() |> Date.add(5),
         creditor_id: "DE98ZZZ09999999999",
         creditor_name: "Example Club",
         creditor_address: nil,
         creditor_iban: "DE87200500001234567890",
         creditor_bic: "",
         sequence_type: :OneOff,
         transaction_information: []
       }}
  """
  @spec new(%{
          :payment_id => String.t(),
          :due_date => any(),
          :creditor_id => String.t(),
          :creditor_name => String.t(),
          :creditor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(
        %{
          payment_id: payment_id,
          due_date: %Date{} = due_date,
          creditor_id: creditor_id,
          creditor_name: creditor_name,
          creditor_iban: creditor_iban
        } = payment_information
      )
      when is_binary(payment_id) and is_binary(creditor_id) and
             is_binary(creditor_name) and is_binary(creditor_iban) do
    with {:ok, new_payment_id} <- FieldValidation.max_text(:payment_id, payment_id, 35),
         :ok <- FieldValidation.due_date(due_date),
         {:ok, new_creditor_id} <- FieldValidation.creditor_identifier(creditor_id),
         {:ok, new_creditor_name} <- FieldValidation.max_text(:creditor_name, creditor_name, 70),
         :ok <- FieldValidation.iban(creditor_iban),
         {:ok, optional_data} <- get_optional_data(payment_information) do
      {:ok,
       %__MODULE__{
         payment_id: new_payment_id,
         due_date: due_date,
         creditor_id: new_creditor_id,
         creditor_name: new_creditor_name,
         creditor_iban: creditor_iban,
         creditor_bic: optional_data.creditor_bic,
         sequence_type: optional_data.sequence_type,
         transaction_information: optional_data.transaction_information,
         creditor_address: optional_data.creditor_address
       }}
    end
  end

  def new(
        %{
          payment_id: payment_id,
          due_date: _due_date,
          creditor_id: creditor_id,
          creditor_name: creditor_name,
          creditor_iban: creditor_iban
        } = _payment_information
      )
      when is_binary(payment_id) and is_binary(creditor_id) and
             is_binary(creditor_name) and is_binary(creditor_iban) do
    {:error, "Parameter due_date must be a date"}
  end

  def new(payment_information) do
    missing_keys = @enforce_keys -- Map.keys(payment_information)

    if missing_keys == [] do
      FieldValidation.text(
        [
          {:payment_id, payment_information[:payment_id]},
          {:creditor_id, payment_information[:creditor_id]},
          {:creditor_name, payment_information[:creditor_name]},
          {:creditor_iban, payment_information[:creditor_iban]}
        ],
        "Parameters must be strings."
      )
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end

  defp get_optional_data(payment_information) do
    with {:ok, creditor_bic} <- get_creditor_bic(payment_information),
         {:ok, sequence_type} <- get_sequence_type(payment_information),
         {:ok, transaction_information} <- get_transaction_information(payment_information),
         {:ok, creditor_address} <-
           ExSepa.Schema.Address.get_address(payment_information, :creditor_address),
         :ok <- FieldValidation.bic(creditor_bic) do
      {:ok,
       %{
         creditor_bic: creditor_bic,
         sequence_type: sequence_type,
         transaction_information: transaction_information,
         creditor_address: creditor_address
       }}
    end
  end

  defp get_creditor_bic(payment_information) do
    case Map.fetch(payment_information, :creditor_bic) do
      {:ok, creditor_bic} when is_binary(creditor_bic) ->
        {:ok, creditor_bic}

      {:ok, creditor_bic} ->
        FieldValidation.text([{:creditor_bic, creditor_bic}], "Parameters must be strings.")

      :error ->
        {:ok, ""}
    end
  end

  defp get_sequence_type(payment_information) do
    case Map.fetch(payment_information, :sequence_type) do
      {:ok, sequence_type} ->
        if sequence_type in @sequence_type3_code_atom,
          do: {:ok, sequence_type},
          else:
            {:error,
             "Parameter sequence_type must be an atom :#{Enum.join(@sequence_type3_code_atom, ", :")}"}

      :error ->
        {:ok, List.first(@sequence_type3_code_atom)}
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

  @doc false
  # """
  # Converts the sequence type into the corresponding code.
  # """
  def get_sequenz_type_code(sequence_type) do
    @sequence_type3_code[sequence_type]
  end
end

defmodule ExSepa.DirectDebit.PaymentInformationError do
  @moduledoc false
  defexception [:message]
end
