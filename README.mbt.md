# moonbit-csv

`moonbit-csv` is a lightweight CSV parser and writer for MoonBit.

The project now ships a working first version of the CSV core:

- string-to-rows parsing
- rows-to-string writing
- quoted fields
- escaped quotes (`""`)
- empty fields
- `\n` and `\r\n` records
- structured parse errors through `parse_result`
- GitHub Actions CI and release workflows

## Public API

- `parse(input)` -> parse CSV text into rows, abort on invalid input
- `parse_result(input)` -> parse CSV text into `Result[CsvRows, CsvError]`
- `parse_with(input, options)` -> parse with custom delimiter / strict mode
- `stringify(rows)` -> encode rows into CSV text
- `stringify_with(rows, options)` -> encode with custom delimiter / line ending

## Package layout

- `src/` public API package
- `src/parser/` parser state machine
- `src/writer/` CSV writer
- `src/types/` shared types and options
- `src/cmd/demo/` runnable demo package

## Local commands

```bash
moon fmt --check
moon check
moon test
moon run src/cmd/demo
moon package
```

## Status

- core parser implemented
- core writer implemented
- tests cover common and edge cases
- GitHub Actions CI added
- GitHub release packaging added

## Example

```mbt
let csv = "name,quote\nMoonBit,\"fast, simple, fun\""
let rows = parse(csv)
let text = stringify(rows)
```

## Publish Notes

- The module name is currently set to `sikadi123/moonbit-csv`
- Keep the module name aligned with your authenticated Mooncakes username
- Add a real `repository` field to `moon.mod` before packaging for release
- Run `moon login` before `moon publish`
