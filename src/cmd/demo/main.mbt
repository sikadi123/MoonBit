///|
fn main {
  let sample = "name,lang,quote\nMoonBit,mbt,\"fast, simple, fun\"\nRust,rs,\"safe systems\""
  let rows = @csv.parse(sample)
  let table = @csv.parse_table(sample)
  let first_lang = @csv.get_cell(table, 0, "lang")
  let langs = @csv.column_values(table, "lang")
  let missing = @csv.missing_headers(table, ["name", "lang", "score"])
  let projected = @csv.select_columns(table, ["name", "quote"])
  let first_record = @csv.record(table, 0)
  let rebuilt = @csv.stringify_table(table)
  let encoded = @csv.stringify([
    ["name", "lang", "quote"],
    ["MoonBit", "mbt", "fast, simple, fun"],
    ["Rust", "rs", "safe systems"],
  ])
  println("parsed rows: \{@debug.to_string(rows)}")
  println("table header: \{@debug.to_string(table.header)}")
  println("table body: \{@debug.to_string(table.rows)}")
  println(
    "table size: \{@csv.row_count(table)} rows x \{@csv.column_count(table)} columns",
  )
  println("lang of first row: \{@debug.to_string(first_lang)}")
  println("all langs: \{@debug.to_string(langs)}")
  println("missing required headers: \{@debug.to_string(missing)}")
  println("first record: \{@debug.to_string(first_record)}")
  println("selected columns: \{@debug.to_string(projected)}")
  println("stringified from table:\n\{rebuilt}")
  println("stringified again:\n\{encoded}")
}
