defmodule ExSepa.Schema.AddressTest do
  use ExUnit.Case, async: true
  import ExSepa.Validation.CountryCodes, only: [get_bic_country_codes: 0]
  import XmlBuilder, only: [generate: 1]
  doctest ExSepa.Schema.Address

  describe "ExSepa.Schema.Address.new/1" do
    test "builds a structured address" do
      city = Faker.Address.city()
      country_codes = Enum.drop(get_bic_country_codes(), -1)

      country =
        Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

      assert ExSepa.Schema.Address.new(%{town_name: city, country: country}) ==
               {:ok,
                %ExSepa.Schema.Address{
                  department: nil,
                  sub_department: nil,
                  street_name: nil,
                  building_number: nil,
                  building_name: nil,
                  floor: nil,
                  post_box: nil,
                  room: nil,
                  post_code: nil,
                  town_name: city,
                  town_location_name: nil,
                  district_name: nil,
                  country_sub_division: nil,
                  country: country,
                  address_lines: nil
                }}
    end

    test "builds a structured address with additional fields" do
      city = Faker.Address.city()
      country_sub_division = Faker.Address.state()
      room = Faker.Address.secondary_address()
      street_name = Faker.Address.street_name()
      building_number = Faker.Address.building_number()
      post_code = Faker.Address.zip_code()
      country_codes = Enum.drop(get_bic_country_codes(), -1)

      country =
        Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

      assert ExSepa.Schema.Address.new(%{
               town_name: city,
               country: country,
               post_code: post_code,
               building_number: building_number,
               street_name: street_name,
               room: room,
               country_sub_division: country_sub_division
             }) ==
               {:ok,
                %ExSepa.Schema.Address{
                  department: nil,
                  sub_department: nil,
                  street_name: street_name,
                  building_number: building_number,
                  building_name: nil,
                  floor: nil,
                  post_box: nil,
                  room: room,
                  post_code: post_code,
                  town_name: city,
                  town_location_name: nil,
                  district_name: nil,
                  country_sub_division: country_sub_division,
                  country: country,
                  address_lines: nil
                }}
    end

    test "builds a hybrid address with one address line" do
      assert ExSepa.Schema.Address.new(%{
               town_name: "Berlin",
               country: "DE",
               address_lines: ["Unter den Linden 1"]
             }) ==
               {:ok,
                %ExSepa.Schema.Address{
                  town_name: "Berlin",
                  country: "DE",
                  address_lines: ["Unter den Linden 1"]
                }}
    end

    test "fail: unstructured addresses with address lines only are not supported" do
      assert ExSepa.Schema.Address.new(%{
               address_lines: ["CITY HALL GROTE MARKT 1", "1000 BRUSSELS"]
             }) ==
               {:error,
                "unstructured addresses are not supported; address_lines require both town_name and country"}
    end

    test "fail: unstructured addresses with country but without town_name are not supported" do
      assert ExSepa.Schema.Address.new(%{
               country: "DE",
               address_lines: ["Musterstrasse 1", "10115 Berlin"]
             }) ==
               {:error,
                "unstructured addresses are not supported; address_lines require both town_name and country"}
    end

    test "fail: address_lines is not a list" do
      assert ExSepa.Schema.Address.new(%{
               town_name: "Berlin",
               country: "DE",
               address_lines: "Street 1"
             }) == {:error, "address_lines: must be a list"}
    end

    test "fail: address_lines is empty when provided" do
      assert ExSepa.Schema.Address.new(%{
               town_name: "Berlin",
               country: "DE",
               address_lines: []
             }) == {:error, "address_lines: must contain 1 or 2 lines"}
    end

    test "fail: address_lines has too many entries" do
      assert ExSepa.Schema.Address.new(%{
               town_name: "Berlin",
               country: "DE",
               address_lines: ["Street 1", "Building A", "Third line"]
             }) == {:error, "address_lines: must contain at most 2 lines"}
    end

    test "fail: address_lines contains non-string entry" do
      assert ExSepa.Schema.Address.new(%{
               town_name: "Berlin",
               country: "DE",
               address_lines: ["Street 1", 123]
             }) ==
               {:error,
                "Parameters must be strings. - address_lines[1]: must be UTF-8 encoded binary"}
    end

    test "fail: address_lines without required hybrid fields are rejected" do
      assert ExSepa.Schema.Address.new(%{
               street_name: "Main Street",
               address_lines: ["Main Street 1"]
             }) ==
               {:error,
                "unstructured addresses are not supported; address_lines require both town_name and country"}
    end

    test "fail: hybrid address cannot repeat structured content in address lines" do
      assert ExSepa.Schema.Address.new(%{
               town_name: "Berlin",
               country: "DE",
               street_name: "Unter den Linden",
               address_lines: ["Unter den Linden"]
             }) ==
               {:error,
                "address_lines: must not repeat structured address element 'Unter den Linden'"}
    end

    test "fail: hybrid address without country" do
      assert ExSepa.Schema.Address.new(%{
               town_name: "Berlin",
               address_lines: ["Street 1"]
             }) == {:error, "missing keys: [:country]"}
    end

    test "fail: non-SEPA ISO country codes are rejected in the current address flow" do
      assert ExSepa.Schema.Address.new(%{
               town_name: "New York",
               country: "US"
             }) == {:error, "Country code not in list!"}
    end

    test "fail: address without town_name and country" do
      assert ExSepa.Schema.Address.new(%{}) == {:error, "missing keys: [:town_name, :country]"}
    end

    test "fail: address is not a map" do
      assert ExSepa.Schema.Address.new("Berlin") == {:error, "address: must be a map"}
    end
  end

  describe "ExSepa.Schema.Address.get_address/2" do
    test "fail: creditor_address is not a map" do
      assert ExSepa.Schema.Address.get_address(%{creditor_address: "Berlin"}, :creditor_address) ==
               {:error, "creditor_address: must be a map"}
    end

    test "fail: debtor_address is not a map" do
      assert ExSepa.Schema.Address.get_address(%{debtor_address: "Berlin"}, :debtor_address) ==
               {:error, "debtor_address: must be a map"}
    end

    test "parses a valid address map" do
      assert ExSepa.Schema.Address.get_address(
               %{creditor_address: %{town_name: "Berlin", country: "DE"}},
               :creditor_address
             ) == {:ok, %ExSepa.Schema.Address{town_name: "Berlin", country: "DE"}}
    end
  end

  describe "ExSepa.Schema.Address.to_xml/1" do
    test "serializes structured and hybrid address fields into XML" do
      address = %ExSepa.Schema.Address{
        department: "Ops",
        street_name: "Unter den Linden",
        building_number: "1",
        post_code: "10117",
        town_name: "Berlin",
        country_sub_division: "Berlin",
        country: "DE",
        address_lines: ["Floor 3", "Reception"]
      }

      xml =
        address
        |> ExSepa.Schema.Address.to_xml()
        |> generate()

      assert xml =~ "<Dept>Ops</Dept>"
      assert xml =~ "<StrtNm>Unter den Linden</StrtNm>"
      assert xml =~ "<BldgNb>1</BldgNb>"
      assert xml =~ "<PstCd>10117</PstCd>"
      assert xml =~ "<TwnNm>Berlin</TwnNm>"
      assert xml =~ "<CtrySubDvsn>Berlin</CtrySubDvsn>"
      assert xml =~ "<Ctry>DE</Ctry>"
      assert xml =~ "<AdrLine>Floor 3</AdrLine>"
      assert xml =~ "<AdrLine>Reception</AdrLine>"
    end
  end
end
