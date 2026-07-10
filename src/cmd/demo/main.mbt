///|
fn main {
  let sample = "name,quote\nMoonBit,\"fast, simple, fun\""
  let rows = @csv.parse(sample)
  let encoded = @csv.stringify([
    ["name", "quote"],
    ["MoonBit", "fast, simple, fun"],
  ])
  println("parsed rows: \{@debug.to_string(rows)}")
  println("stringified again:\n\{encoded}")
}
