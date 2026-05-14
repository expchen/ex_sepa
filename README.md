# ExSepa

> ⚠️ Work in progress, not ready for production ⚡

ExSepa is an Elixir library for generating SEPA XML messages.
It supports SEPA Core Direct Debits, SEPA Credit Transfers, and SEPA Instant Credit Transfers.
Generated XML data is validated against XML Schema Definitions (XSDs) provided by the German Banking Industry.

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
