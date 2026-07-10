///|
fn main {
  let sample = "name,lang,quote\nMoonBit,mbt,\"fast, simple, fun\"\nRust,rs,\"safe systems\""
  let rows = @csv.parse(sample)
  let table = @csv.parse_table(sample)
  let first_lang = @csv.get_cell(table, 0, "lang")
  let encoded = @csv.stringify([
    ["name", "lang", "quote"],
    ["MoonBit", "mbt", "fast, simple, fun"],
    ["Rust", "rs", "safe systems"],
  ])
  println("parsed rows: \{@debug.to_string(rows)}")
  println("table header: \{@debug.to_string(table.header)}")
  println("table body: \{@debug.to_string(table.rows)}")
  println("lang of first row: \{@debug.to_string(first_lang)}")
  println("stringified again:\n\{encoded}")
}
