///|
test "parse empty input" {
  @test.assert_eq(parse(""), [])
}

///|
test "stringify empty rows" {
  @test.assert_eq(stringify([]), "")
}

///|
test "parse simple csv" {
  @test.assert_eq(parse("a,b\nc,d"), [["a", "b"], ["c", "d"]])
}

///|
test "parse quoted fields and commas" {
  @test.assert_eq(parse("name,quote\nMoonBit,\"fast, simple, fun\""), [
    ["name", "quote"],
    ["MoonBit", "fast, simple, fun"],
  ])
}

///|
test "parse escaped quotes" {
  @test.assert_eq(parse("title\n\"say \"\"hello\"\"\""), [
    ["title"],
    ["say \"hello\""],
  ])
}

///|
test "parse multiline quoted field" {
  @test.assert_eq(parse("id,body\n1,\"hello\nworld\""), [
    ["id", "body"],
    ["1", "hello\nworld"],
  ])
}

///|
test "parse crlf records and trailing empty field" {
  @test.assert_eq(parse("a,b,\r\nc,d,e"), [["a", "b", ""], ["c", "d", "e"]])
}

///|
test "parse custom delimiter" {
  let options = { ..default_parse_options(), delimiter: ';' }
  @test.assert_eq(parse_with("name;lang\nmoonbit;mbt", options), [
    ["name", "lang"],
    ["moonbit", "mbt"],
  ])
}

///|
test "parse_result returns unclosed quote error" {
  debug_inspect(
    parse_result("\"hello"),
    content=(
      #|Err(
      #|  {
      #|    kind: UnclosedQuote,
      #|    line: 1,
      #|    column: 7,
      #|    message: "reached the end of input before the quoted field was closed",
      #|  },
      #|)
    ),
  )
}

///|
test "parse_result returns invalid quote error" {
  debug_inspect(
    parse_result("ab\"c"),
    content=(
      #|Err(
      #|  {
      #|    kind: UnexpectedQuote,
      #|    line: 1,
      #|    column: 3,
      #|    message: "a quote may only appear at the start of a field",
      #|  },
      #|)
    ),
  )
}

///|
test "strict column count detects mismatch" {
  let options = { ..default_parse_options(), strict_column_count: true }
  debug_inspect(
    parse_with_result("a,b\nc", options),
    content=(
      #|Err(
      #|  {
      #|    kind: InconsistentColumnCount,
      #|    line: 2,
      #|    column: 1,
      #|    message: "expected 2 columns, but found 1 columns",
      #|  },
      #|)
    ),
  )
}

///|
test "stringify quotes special fields" {
  @test.assert_eq(
    stringify([["a,b", "say \"hello\"", "line1\nline2"]]),
    "\"a,b\",\"say \"\"hello\"\"\",\"line1\nline2\"",
  )
}

///|
test "stringify custom options" {
  let options : WriteOptions = {
    delimiter: ';',
    line_ending: "\r\n",
    always_quote: true,
  }
  @test.assert_eq(
    stringify_with([["name", "lang"], ["moonbit", "mbt"]], options),
    "\"name\";\"lang\"\r\n\"moonbit\";\"mbt\"",
  )
}

///|
test "roundtrip parse and stringify" {
  let rows = [["name", "quote"], ["MoonBit", "fast, simple, fun"], ["2", "x"]]
  @test.assert_eq(parse(stringify(rows)), rows)
}
