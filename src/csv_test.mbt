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
test "parse ignores trailing newline without adding empty row" {
  @test.assert_eq(parse("a,b\nc,d\n"), [["a", "b"], ["c", "d"]])
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
test "parse_result returns unexpected character after quote error" {
  debug_inspect(
    parse_result("\"hello\"x"),
    content=(
      #|Err(
      #|  {
      #|    kind: UnexpectedCharacterAfterQuote,
      #|    line: 1,
      #|    column: 8,
      #|    message: "expected a delimiter or a record ending after the closing quote",
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
test "parse table separates header and rows" {
  @test.assert_eq(parse_table("name,lang\nMoonBit,mbt\nRust,rs"), {
    header: ["name", "lang"],
    rows: [["MoonBit", "mbt"], ["Rust", "rs"]],
  })
}

///|
test "parse table with result supports custom delimiter" {
  let options = { ..default_parse_options(), delimiter: ';' }
  @test.assert_eq(
    parse_table_with_result("name;lang\nMoonBit;mbt", options),
    Ok({ header: ["name", "lang"], rows: [["MoonBit", "mbt"]] }),
  )
}

///|
test "header lookup and cell access" {
  let table = parse_table("name,lang\nMoonBit,mbt")
  @test.assert_eq(header_index(table, "lang"), Some(1))
  @test.assert_eq(has_header(table, "lang"), true)
  @test.assert_eq(get_cell(table, 0, "lang"), Some("mbt"))
  @test.assert_eq(get_cell(table, 0, "missing"), None)
}

///|
test "table helpers expose counts and columns" {
  let table = parse_table("name,lang\nMoonBit,mbt\nRust,rs")
  @test.assert_eq(row_count(table), 2)
  @test.assert_eq(column_count(table), 2)
  @test.assert_eq(column_values(table, "name"), Some(["MoonBit", "Rust"]))
}

///|
test "missing headers are reported" {
  let table = parse_table("name,lang\nMoonBit,mbt")
  @test.assert_eq(missing_headers(table, ["name", "score"]), ["score"])
}

///|
test "record access returns named fields" {
  let table = parse_table("name,lang\nMoonBit,mbt")
  @test.assert_eq(
    record(table, 0),
    Some([{ name: "name", value: "MoonBit" }, { name: "lang", value: "mbt" }]),
  )
}

///|
test "records returns all table rows as field pairs" {
  let table = parse_table("name,lang\nMoonBit,mbt\nRust,rs")
  @test.assert_eq(records(table), [
    [{ name: "name", value: "MoonBit" }, { name: "lang", value: "mbt" }],
    [{ name: "name", value: "Rust" }, { name: "lang", value: "rs" }],
  ])
}

///|
test "select columns builds a projected table" {
  let table = parse_table("name,lang,quote\nMoonBit,mbt,fast\nRust,rs,safe")
  @test.assert_eq(
    select_columns(table, ["quote", "name"]),
    Ok({
      header: ["quote", "name"],
      rows: [["fast", "MoonBit"], ["safe", "Rust"]],
    }),
  )
}

///|
test "select columns reports missing headers" {
  let table = parse_table("name,lang\nMoonBit,mbt")
  @test.assert_eq(select_columns(table, ["lang", "score"]), Err(["score"]))
}

///|
test "select columns keeps order and pads missing row cells" {
  let table = parse_table("name,lang,quote\nMoonBit,mbt\nRust,rs,safe")
  @test.assert_eq(
    select_columns(table, ["quote", "name"]),
    Ok({
      header: ["quote", "name"],
      rows: [["", "MoonBit"], ["safe", "Rust"]],
    }),
  )
}

///|
test "table can roundtrip back to rows and csv text" {
  let rows = [["name", "lang"], ["MoonBit", "mbt"], ["Rust", "rs"]]
  let table = to_table(rows)
  @test.assert_eq(from_table(table), rows)
  @test.assert_eq(stringify_table(table), "name,lang\nMoonBit,mbt\nRust,rs")
}

///|
test "table without header roundtrips rows directly" {
  let table : CsvTable = { header: [], rows: [["MoonBit", "mbt"], ["Rust", "rs"]] }
  @test.assert_eq(from_table(table), [["MoonBit", "mbt"], ["Rust", "rs"]])
  @test.assert_eq(stringify_table(table), "MoonBit,mbt\nRust,rs")
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
test "stringify table with custom options uses provided delimiter and line ending" {
  let table : CsvTable = {
    header: ["name", "lang"],
    rows: [["MoonBit", "mbt"], ["Rust", "rs"]],
  }
  let options : WriteOptions = {
    delimiter: ';',
    line_ending: "\r\n",
    always_quote: false,
  }
  @test.assert_eq(
    stringify_table_with(table, options),
    "name;lang\r\nMoonBit;mbt\r\nRust;rs",
  )
}

///|
test "roundtrip parse and stringify" {
  let rows = [["name", "quote"], ["MoonBit", "fast, simple, fun"], ["2", "x"]]
  @test.assert_eq(parse(stringify(rows)), rows)
}
