defmodule ExSepa.Validation.Field do
  alias ExSepa.Validation.CountryCodes

  @moduledoc """
  Validation helpers for SEPA payment data.

  The existing public validators remain SEPA-specific. In particular,
  `max_text/3` performs EPC character normalization and `country_code/1`
  validates against the SEPA-related country lists.

  The name `max_text/3` is kept for backward compatibility even though its
  behavior is SEPA/EPC-specific. Helpers such as `international_text/3` and
  `iso_country_code/1` provide a broader validation baseline for future
  international or OLO-oriented profiles.
  """

  defp in_language(string, pattern) do
    new_string =
      string
      |> String.replace("ä", "a")
      |> String.replace("ö", "o")
      |> String.replace("ü", "u")
      |> String.replace("Ä", "a")
      |> String.replace("Ö", "o")
      |> String.replace("Ü", "u")
      |> String.replace("ß", "s")
      |> String.replace("&", "+")
      |> String.replace("*", ".")
      |> String.replace("$", ".")
      |> String.replace("%", ".")

    with :ok <-
           do_pattern_test(
             new_string,
             pattern
           ) do
      {:ok, new_string}
    end
  end

  defp do_pattern_test(string, pattern, acc \\ "")

  defp do_pattern_test("", _pattern, acc) do
    if acc == "",
      do: :ok,
      else: {:error, "These characters are not part of the pattern test: #{acc}"}
  end

  defp do_pattern_test(string, pattern, acc) do
    sl = String.length(string)
    run_string = Regex.run(pattern, string)

    if run_string == nil do
      do_pattern_test(String.slice(string, 1, sl - 1), pattern, acc <> String.at(string, 0))
    else
      new_string = Enum.join(run_string)
      nsl = String.length(new_string)

      if sl == nsl do
        do_pattern_test("", pattern, acc)
      else
        if new_string == String.slice(string, 0..(nsl - 1)) do
          do_pattern_test(
            String.slice(string, nsl + 1, sl - nsl - 1),
            pattern,
            acc <> String.at(string, nsl)
          )
        else
          do_pattern_test(new_string, pattern, acc <> String.at(string, 0))
        end
      end
    end
  end

  @doc """
  Verifies that the provided values are UTF-8 encoded binaries.

  This helper is mainly used to produce consistent validation errors for one or
  more fields.
  """
  @spec text(keyword(binary())) :: :ok | {:error, String.t()}
  def text(text_tuple_list, pre_error_text \\ "") do
    case do_text(text_tuple_list, pre_error_text) do
      "" -> :ok
      e -> {:error, e}
    end
  end

  defp do_text([], acc), do: acc

  defp do_text([first | rest], acc) do
    {ato, tex} = first

    do_text(
      rest,
      acc <>
        case real_text(tex) do
          :ok ->
            ""

          {:error, e} ->
            " - #{ato}: " <> e
        end
    )
  end

  defp real_text(text) do
    with true <- is_binary(text),
         true <- String.valid?(text) do
      :ok
    else
      false ->
        {:error, "must be UTF-8 encoded binary"}
    end
  end

  defp character_set_start(text) do
    if text |> String.starts_with?("/"),
      do: {:error, "Text field must not begin with '/'"},
      else: :ok
  end

  defp character_set_end(text) do
    if text |> String.ends_with?("/"),
      do: {:error, "Text field must not end with '/'"},
      else: :ok
  end

  defp character_set_contain(text) do
    if text |> String.contains?("//"),
      do: {:error, "Text field must not contain '//'"},
      else: :ok
  end

  defp min_max_text(text, min_length, max_length) do
    case String.length(text) do
      x when x < min_length -> {:error, "Minimum length of #{min_length} characters"}
      x when x > max_length -> {:error, "Maximum length of #{max_length} characters"}
      _ -> :ok
    end
  end

  @doc """
  Validates text using the current EPC/SEPA rules and returns the normalized result.
  """
  @spec max_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def max_text(element, text, length) do
    validate_text(element, text, length)
  end

  @doc """
  Optional variant of `max_text/3` using the current EPC/SEPA rules.
  """
  @spec optional_max_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def optional_max_text(element, text, length) do
    validate_optional_text(element, text, length)
  end

  @doc """
  Validates text for broader international use.

  Unlike `max_text/3`, this helper does not transliterate or restrict input to EPC character subset. It validates UTF-8, trims surrounding whitespace, enforces length limits, and keeps the existing slash formatting rules used by current payment text fields.
  """
  @spec international_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def international_text(element, text, length) do
    validate_international_text(element, text, length)
  end

  @doc """
  Optional variant of `international_text/3`.
  """
  @spec optional_international_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def optional_international_text(element, text, length) do
    validate_optional_international_text(element, text, length)
  end

  @spec validate_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp validate_text(element, text, length) do
    with :ok <- real_text(text),
         trimmed_text = String.trim(text),
         :ok <- min_max_text(trimmed_text, 1, length),
         {:ok, validated_text} <- do_validate_text(trimmed_text, length) do
      {:ok, validated_text}
    else
      {:error, error} -> {:error, "#{element}: #{error}"}
    end
  end

  @spec validate_optional_text(
          atom(),
          String.t(),
          non_neg_integer()
        ) :: {:ok, String.t()} | {:error, String.t()}
  defp validate_optional_text(element, text, length) do
    with :ok <- real_text(text) do
      if String.trim(text) == "" do
        {:ok, ""}
      else
        validate_text(element, text, length)
      end
    end
  end

  @spec validate_international_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp validate_international_text(element, text, length) do
    with :ok <- real_text(text),
         trimmed_text = String.trim(text),
         :ok <- min_max_text(trimmed_text, 1, length),
         :ok <- validate_slash_rules(trimmed_text) do
      {:ok, trimmed_text}
    else
      {:error, error} -> {:error, "#{element}: #{error}"}
    end
  end

  @spec validate_optional_international_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp validate_optional_international_text(element, text, length) do
    with :ok <- real_text(text) do
      if String.trim(text) == "" do
        {:ok, ""}
      else
        validate_international_text(element, text, length)
      end
    end
  end

  defp do_validate_text(text, length) do
    with {:ok, language_text} <-
           in_language(
             text,
             ~r/[a-zA-Z0-9|\x2F|\x2D|\x3F|\x3A|\x28|\x29|\x2E|\x20|\x2C|\x27|\x2B]{1,#{length}}/
           ),
         :ok <- validate_slash_rules(language_text) do
      {:ok, language_text}
    end
  end

  defp validate_slash_rules(text) do
    with :ok <- character_set_start(text),
         :ok <- character_set_end(text),
         :ok <- character_set_contain(text) do
      :ok
    end
  end

  @doc """
  Checks the amount entered. It must be between 0.01 and 999,999,999.99 euros.

  ## Examples

      iex> ExSepa.Validation.Field.amount(50.0)
      :ok

      iex> ExSepa.Validation.Field.amount(0.0)
      {:error, "The amount must be more then 0.00"}

      iex> ExSepa.Validation.Field.amount(-53.15)
      {:error, "The amount must be more then 0.00"}

      iex> ExSepa.Validation.Field.amount(4561237531.0)
      {:error, "The amount must be less then 999,999,999.99 euro"}

      iex> ExSepa.Validation.Field.amount(30.303)
      {:error, "Amount has too many decimal places"}
  """
  @spec amount(float()) :: :ok | {:error, String.t()}
  def amount(amount) do
    if amount <= 0.0 do
      {:error, "The amount must be more then 0.00"}
    else
      integer = round(amount * 100)

      if length(Integer.digits(integer)) > 11 do
        {:error, "The amount must be less then 999,999,999.99 euro"}
      else
        if integer / 100.0 == amount do
          :ok
        else
          {:error, "Amount has too many decimal places"}
        end
      end
    end
  end

  @doc """
  Validates that the due date lies in the future.
  """
  @spec due_date(Date.t()) :: :ok | {:error, String.t()}
  def due_date(%Date{} = date) do
    case Date.compare(Date.utc_today(), date) do
      :lt -> :ok
      _ -> {:error, "The due date must be in the future."}
    end
  end

  @doc """
  Validates that the date lies in the past.
  """
  @spec date(Date.t()) :: :ok | {:error, String.t()}
  def date(%Date{} = date) do
    case Date.compare(date, Date.utc_today()) do
      :lt -> :ok
      _ -> {:error, "Date must be in the past."}
    end
  end

  @doc """
  Validates an IBAN.
  """
  @spec iban(String.t()) :: :ok | {:error, String.t()}
  def iban(iban) do
    case Bankster.iban_validate(iban) do
      {:ok, _iban} -> :ok
      {:error, e} -> {:error, e}
    end
  end

  @doc """
  Validates a BIC.

  An empty string is accepted, because some validation paths only require a BIC
  in specific SEPA scenarios.
  """
  @spec bic(String.t()) :: :ok | {:error, String.t()}
  def bic(bic) do
    if bic == "" do
      :ok
    else
      case Bankster.bic_valid?(bic) do
        true -> :ok
        false -> {:error, "BIC is not valid"}
      end
    end
  end

  @doc """
  Validates a country code using the default EPC strict rules.
  """
  @spec country_code(String.t()) :: :ok | {:error, String.t()}
  def country_code(country) do
    with :ok <- do_pattern_test(country, ~r/[A-Z]{2,2}/) do
      if Enum.member?(CountryCodes.get_bic_country_codes(), country) do
        :ok
      else
        {:error, "Country code not in list!"}
      end
    end
  end

  @doc """
  Validates an ISO 3166-1 alpha-2 country code.

  This helper is broader than `country_code/1` and is intended for OLO-oriented validation flows.
  """
  @spec iso_country_code(String.t()) :: :ok | {:error, String.t()}
  def iso_country_code(country) do
    with :ok <- do_pattern_test(country, ~r/[A-Z]{2,2}/) do
      if CountryCodes.valid_iso_country_code?(country) do
        :ok
      else
        {:error, "Country code not in ISO list!"}
      end
    end
  end

  @doc """
  Validates a SEPA creditor identifier (AT-E005).
  """
  @spec creditor_identifier(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def creditor_identifier(creditor_identifier) do
    with :ok <- real_text(creditor_identifier),
         trimmed_creditor_identifier = String.trim(creditor_identifier),
         :ok <- min_max_text(trimmed_creditor_identifier, 8, 35),
         {:ok, validated_creditor_identifier} <-
           in_language(
             trimmed_creditor_identifier,
             ~r/[a-zA-Z0-9|\x2F|\x2D|\x3F|\x3A|\x28|\x29|\x2E|\x20|\x2C|\x27|\x2B]{1,35}/
           ),
         :ok <- validate_slash_rules(validated_creditor_identifier),
         :ok <- validate_creditor_identifier_structure(validated_creditor_identifier) do
      {:ok, validated_creditor_identifier}
    else
      {:error, error} -> {:error, "creditor_id: #{error}"}
    end
  end

  @doc """
  Checks whether the transmitted country code corresponds to one of the EEA
  countries and, if applicable, whether the required BIC and address have been
  specified.

  ## Examples

      iex> ExSepa.Validation.Field.address_mandatory("DE", "", nil)
      :ok

      iex> ExSepa.Validation.Field.address_mandatory("AD", "", nil)
      {:error, "BIC is mandatory for non-EEA SEPA country or territory"}

      iex> ExSepa.Validation.Field.address_mandatory("AD", "CASBADADXXX", nil)
      {:error, "Address is mandatory for non-EEA SEPA country or territory"}

      iex> ExSepa.Validation.Field.address_mandatory("AD", "CASBADADXXX", %ExSepa.Schema.Address{town_name: "Andorra la Vella", country: "AD"})
      :ok
  """
  @spec address_mandatory(String.t(), String.t(), ExSepa.Schema.Address.t() | nil) ::
          :ok | {:error, String.t()}
  def address_mandatory(country, bic, address) do
    validate_address_requirements(country, bic, address)
  end

  @spec validate_address_requirements(
          String.t(),
          String.t(),
          ExSepa.Schema.Address.t() | nil
        ) :: :ok | {:error, String.t()}
  defp validate_address_requirements(country, bic, address) do
    with :ok <- do_pattern_test(country, ~r/[A-Z]{2,2}/) do
      if Enum.member?(CountryCodes.get_eea_iban_country_codes(), country) do
        :ok
      else
        cond do
          bic == "" ->
            {:error, "BIC is mandatory for non-EEA SEPA country or territory"}

          address == nil ->
            {:error, "Address is mandatory for non-EEA SEPA country or territory"}

          true ->
            :ok
        end
      end
    end
  end

  defp validate_creditor_identifier_structure(creditor_identifier) do
    uppercase_creditor_identifier = String.upcase(creditor_identifier)
    country = String.slice(uppercase_creditor_identifier, 0, 2)
    check_digits = String.slice(uppercase_creditor_identifier, 2, 2)
    business_code = String.slice(uppercase_creditor_identifier, 4, 3)
    national_identifier = String.slice(uppercase_creditor_identifier, 7..-1//1)

    with :ok <- country_code(country),
         :ok <- do_pattern_test(check_digits, ~r/[0-9]{2}/),
         :ok <- do_pattern_test(business_code, ~r/[A-Z0-9]{3}/),
         :ok <- validate_creditor_identifier_national_part(national_identifier),
         true <- creditor_identifier_check_digits_valid?(uppercase_creditor_identifier) do
      :ok
    else
      false ->
        {:error, "invalid creditor identifier check digits"}

      {:error, "Country code not in list!"} ->
        {:error, "invalid country code"}

      {:error, "These characters are not part of the pattern test: " <> _rest} ->
        {:error, "invalid creditor identifier structure"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp validate_creditor_identifier_national_part(national_identifier) do
    if national_identifier
       |> String.replace(~r/[^A-Za-z0-9]/, "")
       |> String.length() > 0 do
      :ok
    else
      {:error, "creditor identifier must include a country-specific identifier"}
    end
  end

  defp creditor_identifier_check_digits_valid?(creditor_identifier) do
    expected_check_digits =
      creditor_identifier
      |> creditor_identifier_checksum_payload()
      |> mod97()
      |> then(&(98 - &1))
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    String.slice(creditor_identifier, 2, 2) == expected_check_digits
  end

  defp creditor_identifier_checksum_payload(creditor_identifier) do
    country = String.slice(creditor_identifier, 0, 2)

    creditor_identifier
    |> String.slice(7..-1//1)
    |> String.replace(~r/[^A-Za-z0-9]/, "")
    |> Kernel.<>(country <> "00")
    |> String.to_charlist()
    |> Enum.map_join(fn
      char when char in ?A..?Z -> Integer.to_string(char - 55)
      char -> <<char>>
    end)
  end

  defp mod97(number_string) do
    number_string
    |> String.to_charlist()
    |> Enum.reduce(0, fn char, remainder ->
      rem(remainder * 10 + (char - ?0), 97)
    end)
  end
end
