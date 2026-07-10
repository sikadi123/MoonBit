# moonbit-csv

`moonbit-csv` is a lightweight CSV parser and writer for MoonBit.

This repository is currently in scaffold stage. The project structure, CI checks,
and public API entry points are in place so implementation can proceed package by
package.

## Public API plan

- `parse(input)` -> parse CSV text into rows
- `stringify(rows)` -> encode rows into CSV text

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
```

## Status

- module config added
- package skeleton added
- smoke tests added
- GitHub Actions CI added

## Notes

- The module name is currently set to `sikad/moonbit-csv`
- Update the module name before publishing if your Mooncakes username differs
