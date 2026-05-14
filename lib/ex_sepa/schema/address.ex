defmodule ExSepa.Schema.Address do
  import XmlBuilder
  alias ExSepa.Validation.Field, as: FieldValidation

  @required_fields [:town_name, :country]

  @moduledoc """
  Postal Address: only structured and hybrid addresses are supported.
  Unstructured addresses are not supported.
  """

  @typedoc """
  Address information are only mandatory when the Creditor PSP or the Debtor PSP is located in a non-EEA SEPA country or territory.
  At least `:town_name` and `:country` must be used.
  Hybrid addresses may additionally use up to two `:address_lines`.
  Unstructured addresses are not supported.

  The map has the following keys:
    * `:town_name` Name of a built-up area, with defined boundaries, and a local government (maximum length of 35 characters).
    * `:country` Nation with its own government (CountryCode - Pattern: [A-Z]{2,2}).
    * `:department` OPTIONAL: Identification of a division of a large organisation or building (maximum length of 70 characters).
    * `:sub_department` OPTIONAL: Identification of a subdivision of a large organisation or building (maximum length of 70 characters).
    * `:street_name` OPTIONAL: Name of a street or thoroughfare (maximum length of 70 characters).
    * `:building_number` OPTIONAL: Number that identifies the position of a building on a street (maximum length of 16 characters).
    * `:building_name` OPTIONAL: Name of the building or house (maximum length of 35 characters).
    * `:floor` OPTIONAL: Floor or storey within a building (maximum length of 70 characters).
    * `:post_box` OPTIONAL: Numbered box in a post office, assigned to a person or organisation, where letters are kept until called for (maximum length of 16 characters).
    * `:room` OPTIONAL: Building room number (maximum length of 70 characters).
    * `:post_code` OPTIONAL: Identifier consisting of a group of letters and/or numbers that is added to a postal address to assist the sorting of mail (maximum length of 16 characters).
    * `:town_location_name` OPTIONAL: Specific location name within the town (maximum length of 35 characters).
    * `:district_name` OPTIONAL: Identifies a subdivision within a country subdivision (maximum length of 35 characters).
    * `:country_sub_division` OPTIONAL: Identifies a subdivision of a country such as state, region, county (maximum length of 35 characters).
    * `:address_lines` OPTIONAL: Up to two address lines for a hybrid address (maximum length of 70 characters per line).
  """
  @type t :: %__MODULE__{
          department: String.t() | nil,
          sub_department: String.t() | nil,
          street_name: String.t() | nil,
          building_number: String.t() | nil,
          building_name: String.t() | nil,
          floor: String.t() | nil,
          post_box: String.t() | nil,
          room: String.t() | nil,
          post_code: String.t() | nil,
          town_name: String.t(),
          town_location_name: String.t() | nil,
          district_name: String.t() | nil,
          country_sub_division: String.t() | nil,
          country: String.t(),
          address_lines: list(String.t()) | nil
        }
  defstruct [
    :department,
    :sub_department,
    :street_name,
    :building_number,
    :building_name,
    :floor,
    :post_box,
    :room,
    :post_code,
    :town_name,
    :town_location_name,
    :district_name,
    :country_sub_division,
    :country,
    :address_lines
  ]

  @doc """
  Builds an address using the default SCT validation rules.
  """
  @spec new(map()) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(address_map) when is_map(address_map) do
    with :ok <- reject_unstructured_address(address_map),
         :ok <- validate_required_keys(address_map),
         {:ok, town_name} <- get_required_text(address_map, :town_name, 35),
         {:ok, country} <- get_required_country(address_map),
         {:ok, optional_data} <- get_optional_data(address_map),
         :ok <- validate_hybrid_address_lines(town_name, country, optional_data) do
      {:ok,
       %__MODULE__{
         town_name: town_name,
         country: country,
         department: optional_data.department,
         sub_department: optional_data.sub_department,
         street_name: optional_data.street_name,
         building_number: optional_data.building_number,
         building_name: optional_data.building_name,
         floor: optional_data.floor,
         post_box: optional_data.post_box,
         room: optional_data.room,
         post_code: optional_data.post_code,
         town_location_name: optional_data.town_location_name,
         district_name: optional_data.district_name,
         country_sub_division: optional_data.country_sub_division,
         address_lines: optional_data.address_lines
       }}
    end
  end

  def new(_address), do: {:error, "address: must be a map"}

  defp validate_required_keys(address_map) do
    missing_keys = @required_fields -- Map.keys(address_map)

    if missing_keys == [] do
      :ok
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end

  defp reject_unstructured_address(address_map) do
    has_address_lines = Map.has_key?(address_map, :address_lines)
    has_town_name = Map.has_key?(address_map, :town_name)
    has_country = Map.has_key?(address_map, :country)

    cond do
      not has_address_lines ->
        :ok

      has_town_name and has_country ->
        :ok

      has_town_name ->
        :ok

      true ->
        {:error,
         "unstructured addresses are not supported; address_lines require both town_name and country"}
    end
  end

  defp get_optional_data(payment_information) do
    with {:ok, department} <- get_text(payment_information, :department, 70),
         {:ok, sub_department} <- get_text(payment_information, :sub_department, 70),
         {:ok, street_name} <- get_text(payment_information, :street_name, 70),
         {:ok, building_number} <- get_text(payment_information, :building_number, 16),
         {:ok, building_name} <- get_text(payment_information, :building_name, 35),
         {:ok, floor} <- get_text(payment_information, :floor, 70),
         {:ok, post_box} <- get_text(payment_information, :post_box, 16),
         {:ok, room} <- get_text(payment_information, :room, 70),
         {:ok, post_code} <- get_text(payment_information, :post_code, 16),
         {:ok, town_location_name} <- get_text(payment_information, :town_location_name, 35),
         {:ok, district_name} <- get_text(payment_information, :district_name, 35),
         {:ok, country_sub_division} <- get_text(payment_information, :country_sub_division, 35),
         {:ok, address_lines} <- get_address_lines(payment_information) do
      {:ok,
       %{
         department: department,
         sub_department: sub_department,
         street_name: street_name,
         building_number: building_number,
         building_name: building_name,
         floor: floor,
         post_box: post_box,
         room: room,
         post_code: post_code,
         town_location_name: town_location_name,
         district_name: district_name,
         country_sub_division: country_sub_division,
         address_lines: address_lines
       }}
    end
  end

  defp get_required_text(address_map, field, length) do
    case Map.fetch(address_map, field) do
      {:ok, value} when is_binary(value) ->
        FieldValidation.max_text(field, value, length)

      {:ok, value} ->
        FieldValidation.text([{field, value}], "Parameters must be strings.")

      :error ->
        {:error, "missing keys: [#{inspect(field)}]"}
    end
  end

  defp get_required_country(address_map) do
    case Map.fetch(address_map, :country) do
      {:ok, country} when is_binary(country) ->
        case FieldValidation.country_code(country) do
          :ok -> {:ok, country}
          {:error, _} = error -> error
        end

      {:ok, country} ->
        FieldValidation.text([{:country, country}], "Parameters must be strings.")

      :error ->
        {:error, "missing keys: [:country]"}
    end
  end

  defp get_text(payment_information, field, length) do
    case Map.fetch(payment_information, field) do
      {:ok, value} when is_binary(value) ->
        FieldValidation.max_text(field, value, length)

      {:ok, value} ->
        FieldValidation.text([{field, value}], "Parameters must be strings.")

      :error ->
        {:ok, nil}
    end
  end

  defp get_address_lines(payment_information) do
    case Map.fetch(payment_information, :address_lines) do
      {:ok, address_lines} when is_list(address_lines) ->
        validate_address_lines(address_lines)

      {:ok, _address_lines} ->
        {:error, "address_lines: must be a list"}

      :error ->
        {:ok, nil}
    end
  end

  defp validate_address_lines([]),
    do: {:error, "address_lines: must contain 1 or 2 lines"}

  defp validate_address_lines(address_lines) when length(address_lines) > 2,
    do: {:error, "address_lines: must contain at most 2 lines"}

  defp validate_address_lines(address_lines) do
    Enum.reduce_while(Enum.with_index(address_lines), {:ok, []}, fn {line, index}, {:ok, acc} ->
      case validate_address_line(line, index) do
        {:ok, normalized_line} -> {:cont, {:ok, acc ++ [normalized_line]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp validate_address_line(line, _index) when is_binary(line) do
    FieldValidation.max_text(:address_lines, line, 70)
  end

  defp validate_address_line(line, index) do
    FieldValidation.text(
      [{:"address_lines[#{index}]", line}],
      "Parameters must be strings."
    )
  end

  defp validate_hybrid_address_lines(town_name, country, optional_data) do
    if is_list(optional_data.address_lines) do
      structured_values =
        [
          town_name,
          country,
          optional_data.department,
          optional_data.sub_department,
          optional_data.street_name,
          optional_data.building_number,
          optional_data.building_name,
          optional_data.floor,
          optional_data.post_box,
          optional_data.room,
          optional_data.post_code,
          optional_data.town_location_name,
          optional_data.district_name,
          optional_data.country_sub_division
        ]
        |> Enum.reject(&is_nil/1)

      case find_hybrid_duplicate(optional_data.address_lines, structured_values) do
        nil ->
          :ok

        duplicate ->
          {:error, "address_lines: must not repeat structured address element '#{duplicate}'"}
      end
    else
      :ok
    end
  end

  defp find_hybrid_duplicate(address_lines, structured_values) do
    comparable_values = MapSet.new(Enum.map(structured_values, &comparable_text/1))

    Enum.find_value(address_lines, fn line ->
      if MapSet.member?(comparable_values, comparable_text(line)), do: line, else: nil
    end)
  end

  defp comparable_text(text) do
    text
    |> String.downcase()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  @doc """
  Extracts and validates an optional debtor or creditor address from a map
  using the default SCT validation rules.
  """
  @spec get_address(
          map(),
          :debtor_address | :creditor_address
        ) :: :ok | {:error, any()} | {:ok, nil | ExSepa.Schema.Address.t()}
  def get_address(map, address_atom) do
    case Map.fetch(map, address_atom) do
      {:ok, address} when is_map(address) ->
        ExSepa.Schema.Address.new(address)

      {:ok, _address} ->
        {:error, "#{address_atom}: must be a map"}

      :error ->
        {:ok, nil}
    end
  end

  @doc false
  @spec to_xml(ExSepa.Schema.Address.t()) :: {atom(), any(), any()}
  def to_xml(%ExSepa.Schema.Address{} = address_map) do
    element(:PstlAdr, nil, [
      if address_map.department != nil do
        element(:Dept, nil, address_map.department)
      end,
      if address_map.sub_department != nil do
        element(:SubDept, nil, address_map.sub_department)
      end,
      if address_map.street_name != nil do
        element(:StrtNm, nil, address_map.street_name)
      end,
      if address_map.building_number != nil do
        element(:BldgNb, nil, address_map.building_number)
      end,
      if address_map.building_name != nil do
        element(:BldgNm, nil, address_map.building_name)
      end,
      if address_map.floor != nil do
        element(:Flr, nil, address_map.floor)
      end,
      if address_map.post_box != nil do
        element(:PstBx, nil, address_map.post_box)
      end,
      if address_map.room != nil do
        element(:Room, nil, address_map.room)
      end,
      if address_map.post_code != nil do
        element(:PstCd, nil, address_map.post_code)
      end,
      element(:TwnNm, nil, address_map.town_name),
      if address_map.town_location_name != nil do
        element(:TwnLctnNm, nil, address_map.town_location_name)
      end,
      if address_map.district_name != nil do
        element(:DstrctNm, nil, address_map.district_name)
      end,
      if address_map.country_sub_division != nil do
        element(:CtrySubDvsn, nil, address_map.country_sub_division)
      end,
      element(:Ctry, nil, address_map.country),
      if address_map.address_lines != nil do
        Enum.map(address_map.address_lines, &element(:AdrLine, nil, &1))
      end
    ])
  end
end
