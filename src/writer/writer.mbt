///|
fn needs_quotes(field : String, delimiter : Char, always_quote : Bool) -> Bool {
  if always_quote {
    return true
  }
  for ch in field.to_array() {
    if ch == delimiter || ch == '"' || ch == '\n' || ch == '\r' {
      return true
    }
  }
  false
}

///|
fn write_field(
  builder : StringBuilder,
  field : String,
  options : @types.WriteOptions,
) -> Unit {
  if needs_quotes(field, options.delimiter, options.always_quote) {
    builder.write_char('"')
    for ch in field.to_array() {
      if ch == '"' {
        builder.write_string("\"\"")
      } else {
        builder.write_char(ch)
      }
    }
    builder.write_char('"')
  } else {
    builder.write_string(field)
  }
}

///|
pub fn write_rows_with(
  rows : @types.CsvRows,
  options : @types.WriteOptions,
) -> String {
  if rows.is_empty() {
    return ""
  }

  let builder = StringBuilder()
  let row_count = rows.length()
  for row_index in 0..<row_count {
    let row = rows[row_index]
    let field_count = row.length()
    for field_index in 0..<field_count {
      if field_index > 0 {
        builder.write_char(options.delimiter)
      }
      write_field(builder, row[field_index], options)
    }
    if row_index + 1 < row_count {
      builder.write_string(options.line_ending)
    }
  }
  builder.to_string()
}

///|
pub fn write_rows(rows : @types.CsvRows) -> String {
  write_rows_with(rows, @types.default_write_options())
}
