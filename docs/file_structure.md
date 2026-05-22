# File Structure

This page gives a quick overview of how the ExSepa codebase is organized.

## Top-Level Layout

- `lib/` contains the library source code.
- `test/` contains unit tests and shared test helpers.
- `priv/xsd/` contains XSD files used for XML validation.
- `docs/` contains additional project documentation pages for ExDoc.

## Public API Modules

These modules are the main entry points for library users:

- `lib/ex_sepa.ex`
- `lib/ex_sepa/credit_transfer.ex`
- `lib/ex_sepa/direct_debit.ex`
- `lib/ex_sepa/credit_transfer_instant.ex`

They expose the high-level structs and workflows used to build SEPA messages.

## Domain Models

These modules define the validated data structures that are assembled into SEPA
messages:

- `lib/ex_sepa/schema/group_header.ex`
- `lib/ex_sepa/schema/address.ex`
- `lib/ex_sepa/credit_transfer/payment_information.ex`
- `lib/ex_sepa/credit_transfer/transaction_information.ex`
- `lib/ex_sepa/direct_debit/payment_information.ex`
- `lib/ex_sepa/direct_debit/transaction_information.ex`
- `lib/ex_sepa/credit_transfer_instant/payment_information.ex`
- `lib/ex_sepa/credit_transfer_instant/transaction_information.ex`

In general, these modules expose `new/1` constructors that validate input maps
and return typed structs.

## XML Generation

These modules transform validated structs into ISO 20022 XML documents:

- `lib/ex_sepa/credit_transfer/customer_credit_transfer_initiation_v09.ex`
- `lib/ex_sepa/credit_transfer_instant/customer_credit_transfer_initiation_v09.ex`
- `lib/ex_sepa/direct_debit/customer_direct_debit_initiation_v08.ex`

They are part of the internal document-generation pipeline rather than the
primary public API surface.

## Validation And Support

Supporting modules provide reusable validation and assembly helpers:

- `lib/ex_sepa/validation/field.ex`
- `lib/ex_sepa/validation/country_codes.ex`
- `lib/ex_sepa/validation/xml.ex`
- `lib/ex_sepa/support/payment_initiation.ex`
- `lib/ex_sepa/credit_transfer/scheme.ex`

These modules keep the public API modules smaller by centralizing shared rules
and internal wiring.

## Tests

The test suite mirrors the structure of the library:

- `test/ex_sepa/` contains module-focused tests.
- `test/test_support/` contains helper modules used across tests.

This makes it easier to find tests that correspond to a given source file.
