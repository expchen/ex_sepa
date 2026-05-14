defmodule ExSepa.CountryCodes do
  @moduledoc false

  @type country_code :: String.t()

  @eea_iban_country_codes [
    "AT",
    "BE",
    "BG",
    "CY",
    "CZ",
    "DE",
    "DK",
    "EE",
    "ES",
    "FI",
    "FR",
    "GR",
    "HU",
    "HR",
    "IE",
    "IS",
    "LI",
    "LT",
    "LU",
    "LV",
    "NL",
    "MT",
    "NO",
    "IT",
    "PL",
    "PT",
    "RO",
    "SE",
    "SK",
    "SI"
  ]

  @non_eea_iban_country_codes [
    "AD",
    "CH",
    "GB",
    "MC",
    "SM",
    # Vatican City State not in Faker iban list
    "VA"
  ]

  @iban_country_codes @eea_iban_country_codes ++ @non_eea_iban_country_codes

  @eea_bic_country_codes [
    "AT",
    "BE",
    "BG",
    "BL",
    "CY",
    "CZ",
    "DE",
    "DK",
    "EE",
    "ES",
    "FI",
    "FR",
    "GF",
    "GP",
    "GR",
    "HU",
    "HR",
    "IE",
    "IS",
    "LI",
    "LT",
    "LU",
    "LV",
    "NL",
    "MF",
    "MT",
    "MQ",
    "NO",
    "IT",
    "PL",
    "PT",
    "RE",
    "RO",
    "SE",
    "SK",
    "SI",
    "YT"
  ]

  @non_eea_bic_country_codes [
    "AD",
    "CH",
    "GB",
    "GG",
    "IM",
    "JE",
    "MC",
    "PM",
    "SM",
    # Vatican City State not in Faker iban list
    "VA"
  ]

  @bic_country_codes @eea_bic_country_codes ++ @non_eea_bic_country_codes

  @iso_country_codes ~w(
    AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ
    BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ
    CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ
    DE DJ DK DM DO DZ
    EC EE EG EH ER ES ET
    FI FJ FK FM FO FR
    GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY
    HK HM HN HR HT HU
    ID IE IL IM IN IO IQ IR IS IT
    JE JM JO JP
    KE KG KH KI KM KN KP KR KW KY KZ
    LA LB LC LI LK LR LS LT LU LV LY
    MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ
    NA NC NE NF NG NI NL NO NP NR NU NZ
    OM
    PA PE PF PG PH PK PL PM PN PR PS PT PW PY
    QA
    RE RO RS RU RW
    SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ
    TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ
    UA UG UM US UY UZ
    VA VC VE VG VI VN VU
    WF WS
    YE YT
    ZA ZM ZW
  )

  @doc false
  @spec get_eea_iban_country_codes() :: [country_code()]
  def get_eea_iban_country_codes, do: @eea_iban_country_codes

  @doc false
  @spec get_non_eea_iban_country_codes() :: [country_code()]
  def get_non_eea_iban_country_codes, do: @non_eea_iban_country_codes

  @doc false
  @spec get_iban_country_codes() :: [country_code()]
  def get_iban_country_codes, do: @iban_country_codes

  @doc false
  @spec get_eea_bic_country_codes() :: [country_code()]
  def get_eea_bic_country_codes, do: @eea_bic_country_codes

  @doc false
  @spec get_non_eea_bic_country_codes() :: [country_code()]
  def get_non_eea_bic_country_codes, do: @non_eea_bic_country_codes

  @doc false
  @spec get_bic_country_codes() :: [country_code()]
  def get_bic_country_codes, do: @bic_country_codes

  @doc false
  @spec get_iso_country_codes() :: [country_code()]
  def get_iso_country_codes, do: @iso_country_codes

  @doc false
  @spec valid_iso_country_code?(country_code()) :: boolean()
  def valid_iso_country_code?(country_code) when is_binary(country_code),
    do: country_code in @iso_country_codes

  def valid_iso_country_code?(_country_code), do: false
end
