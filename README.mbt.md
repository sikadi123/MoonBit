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
- CLI and browser playground helpers

## Public API

- `parse(input)` -> parse CSV text into rows, abort on invalid input
- `parse_result(input)` -> parse CSV text into `Result[CsvRows, CsvError]`
- `parse_with(input, options)` -> parse with custom delimiter / strict mode
- `parse_table(input)` -> parse the first row as table header
- `to_table(rows)` / `from_table(table)` -> convert between row-based and table-based views
- `header_index(table, name)` / `get_cell(table, row, name)` -> access cells by column name
- `has_header(table, name)` / `missing_headers(table, names)` -> validate uploaded CSV headers
- `record(table, row)` / `records(table)` -> turn rows into backend-friendly field records
- `column_values(table, name)` -> collect a full column
- `select_columns(table, names)` -> build a projected table from required columns
- `stringify(rows)` -> encode rows into CSV text
- `stringify_with(rows, options)` -> encode with custom delimiter / line ending
- `stringify_table(table)` -> encode a `CsvTable` directly

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
node --test web/app.test.mjs
moon run src/cmd/demo
moon package
```

## Status

- core parser implemented
- core writer implemented
- tests cover common and edge cases
- support layer tests added
- frontend smoke test added
- GitHub Actions CI added
- GitHub release packaging added

## Example

```mbt
let csv = "name,quote\nMoonBit,\"fast, simple, fun\""
let rows = parse(csv)
let text = stringify(rows)
```

## Table Example

```mbt
let table = parse_table("name,lang\nMoonBit,mbt\nRust,rs")

let lang_column = column_values(table, "lang")
let first_name = get_cell(table, 0, "name")
let first_record = record(table, 0)
let csv_text = stringify_table(table)
```

## Recommended Usage

- Use `parse` when invalid input should fail fast
- Use `parse_result` when you want structured error handling
- Use `parse_table` when the first row is a header row
- Use `missing_headers(table, required_headers)` before importing business data
- Use `record(table, row)` or `records(table)` when your backend wants named fields instead of column indexes
- Use `select_columns(table, ["id", "name"])` to keep only the columns your service needs
- Use `parse_with(..., { delimiter: ';', ... })` for non-comma files
- Use `strict_column_count: true` when you need every row width to match
- Use `stringify_with(..., { always_quote: true, ... })` when producing machine-oriented export files

## Publish Notes

- The module name is currently set to `sikadi123/moonbit-csv`
- Keep the module name aligned with your authenticated Mooncakes username
- The `repository` field in `moon.mod` should point to the public source repository
- Run `moon login` before `moon publish`
- Run `moon check`, `moon test`, `node --test web/app.test.mjs`, and `moon package` before release
