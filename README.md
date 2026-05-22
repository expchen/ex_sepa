# ExSepa

> ⚠️ Work in progress, not ready for production ⚡

ExSepa is an Elixir library for generating SEPA customer-to-PSP XML messages.
It currently supports:

- SEPA Core Direct Debit (`pain.008.001.08`)
- SEPA Credit Transfer (`pain.001.001.09`)
- SEPA Instant Credit Transfer (`pain.001.001.09` with `INST`)

Generated XML is validated against the XML Schema Definitions (XSDs) published by Deutsche Kreditwirtschaft.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `ex_sepa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_sepa, "~> 0.1.0"}
  ]
end
```

## Test

Run tests with:

```bash
mix test
```

## Documentation

Once published, the docs can be found at <https://hexdocs.pm/ex_sepa>.
Generate HexDocs with:

```bash
mix docs
```

## Quick Example

### Credit Transfer

```elixir
credit_transfer =
  ExSepa.CreditTransfer.new(%{
    msg_id: "Msg-ID-1001",
    initiating_party_name: "Example GmbH"
  })
  |> ExSepa.CreditTransfer.add_payment_information(%{
    payment_id: "Payment-ID-1001",
    requested_execution_date: Date.utc_today(),
    debtor_name: "Example GmbH",
    debtor_iban: "DE87200500001234567890"
  })
  |> ExSepa.CreditTransfer.add_transaction_information("Payment-ID-1001", %{
    end_to_end_id: "E2E-1001",
    amount: 125.50,
    creditor_name: "Example Supplier",
    creditor_iban: "NL62PXVC6402395035",
    remittance_information: "Invoice 1001"
  })

xml = ExSepa.CreditTransfer.to_xml(credit_transfer)
```

### Direct Debit

```elixir
direct_debit =
  ExSepa.DirectDebit.new(%{
    msg_id: "Msg-ID-2001",
    initiating_party_name: "Example Club"
  })
  |> ExSepa.DirectDebit.add_payment_information(%{
    payment_id: "Payment-ID-2001",
    due_date: Date.utc_today() |> Date.add(5),
    creditor_id: "DE98ZZZ09999999999",
    creditor_name: "Example Club",
    creditor_iban: "DE87200500001234567890"
  })
  |> ExSepa.DirectDebit.add_transaction_information("Payment-ID-2001", %{
    end_to_end_id: "E2E-2001",
    amount: 49.99,
    mandate_id: "MANDATE-2001",
    mandate_signing_date: ~D[2024-01-15],
    debtor_name: "Member One",
    debtor_iban: "DE88100900001234567892",
    remittance_information: "Membership fee"
  })

xml = ExSepa.DirectDebit.to_xml(direct_debit)
```

### Instant Credit Transfer

```elixir
instant_credit_transfer =
  ExSepa.CreditTransferInstant.new(%{
    msg_id: "Msg-ID-3001",
    initiating_party_name: "Example GmbH"
  })
  |> ExSepa.CreditTransferInstant.add_payment_information(%{
    payment_id: "Payment-ID-3001",
    requested_execution_date: DateTime.add(DateTime.utc_now(), 60, :second),
    instruction_priority: :High,
    debtor_name: "Example GmbH",
    debtor_iban: "DE87200500001234567890"
  })
  |> ExSepa.CreditTransferInstant.add_transaction_information("Payment-ID-3001", %{
    end_to_end_id: "E2E-3001",
    amount: 15.25,
    creditor_name: "Example Merchant",
    creditor_iban: "NL62PXVC6402395035",
    remittance_information: "Instant settlement"
  })

xml = ExSepa.CreditTransferInstant.to_xml(instant_credit_transfer)
```
