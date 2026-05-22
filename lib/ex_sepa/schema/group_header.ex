defmodule ExSepa.Schema.GroupHeader do
  alias ExSepa.Validation.Field, as: FieldValidation

  @moduledoc """
  Public group header model shared by all transactions in a SEPA message.

  A group header identifies the message as a whole and stores the initiating
  party name used in the generated XML.

  ## Required Fields

    * `:msg_id` - unique message identifier
    * `:initiating_party_name` - name of the initiating party
  """

  @enforce_keys [:msg_id, :initiating_party_name]
  @typedoc false
  @type t :: %__MODULE__{
          msg_id: String.t(),
          initiating_party_name: String.t()
        }
  defstruct [:msg_id, :initiating_party_name]

  @doc """
  Validates input and builds a group header struct.

  Required keys are `:msg_id` and `:initiating_party_name`.

  Both values must be UTF-8 strings and are validated against the EPC text
  rules. `:msg_id` is limited to 35 characters and
  `:initiating_party_name` is limited to 70 characters.

  ## Examples

      iex> ExSepa.Schema.GroupHeader.new(%{
      ...>   msg_id: "Msg-ID-0001",
      ...>   initiating_party_name: "Example GmbH"
      ...> })
      {:ok,
       %ExSepa.Schema.GroupHeader{
         msg_id: "Msg-ID-0001",
         initiating_party_name: "Example GmbH"
       }}
  """
  @spec new(%{
          msg_id: String.t(),
          initiating_party_name: String.t()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(%{msg_id: msg_id, initiating_party_name: initiating_party_name})
      when is_binary(msg_id) and is_binary(initiating_party_name) do
    with {:ok, new_msg_id} <- FieldValidation.max_text(:msg_id, msg_id, 35),
         {:ok, new_initiating_party_name} <-
           FieldValidation.max_text(:initiating_party_name, initiating_party_name, 70) do
      {:ok,
       %__MODULE__{
         msg_id: new_msg_id,
         initiating_party_name: new_initiating_party_name
       }}
    end
  end

  def new(group_header_map) do
    missing_keys = @enforce_keys -- Map.keys(group_header_map)

    if missing_keys == [] do
      with :ok <-
             FieldValidation.text(
               [
                 {:msg_id, group_header_map[:msg_id]},
                 {:initiating_party_name, group_header_map[:initiating_party_name]}
               ],
               "Parameters must be strings."
             ) do
        {:error, "Something has gone wrong: #{group_header_map}"}
      end
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end
end

defmodule ExSepa.Schema.GroupHeaderError do
  @moduledoc false
  defexception [:message]
end
