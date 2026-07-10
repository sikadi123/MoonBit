///|
fn error(
  kind : @types.CsvErrorKind,
  line : Int,
  column : Int,
  message : String,
) -> Result[@types.CsvRows, @types.CsvError] {
  Err({ kind, line, column, message })
}

///|
fn finish_record(
  rows : @types.CsvRows,
  current_row : Array[String],
  expected_columns : Int?,
  options : @types.ParseOptions,
  line : Int,
) -> Result[Int?, @types.CsvError] {
  let width = current_row.length()
  if options.strict_column_count {
    match expected_columns {
      None => {
        rows.push(current_row)
        Ok(Some(width))
      }
      Some(expected) =>
        if expected == width {
          rows.push(current_row)
          Ok(expected_columns)
        } else {
          Err({
            kind: @types.CsvErrorKind::InconsistentColumnCount,
            line,
            column: 1,
            message: "expected \{expected} columns, but found \{width} columns",
          })
        }
    }
  } else {
    rows.push(current_row)
    Ok(expected_columns)
  }
}

///|
pub fn parse_rows_result(
  input : String,
  options : @types.ParseOptions,
) -> Result[@types.CsvRows, @types.CsvError] {
  if input == "" {
    return Ok([])
  }

  let chars = input.to_array()
  let total = chars.length()
  let rows : @types.CsvRows = []
  let mut current_row : Array[String] = []
  let mut field = StringBuilder()
  let mut expected_columns : Int? = None
  let mut index = 0
  let mut line = 1
  let mut column = 1
  let mut in_quotes = false
  let mut just_closed_quote = false
  let mut at_field_start = true

  while index < total {
    let ch = chars[index]
    if in_quotes {
      if ch == '"' {
        if index + 1 < total && chars[index + 1] == '"' {
          field.write_char('"')
          index = index + 2
          column = column + 2
        } else {
          in_quotes = false
          just_closed_quote = true
          index = index + 1
          column = column + 1
        }
      } else {
        field.write_char(ch)
        index = index + 1
        if ch == '\n' {
          line = line + 1
          column = 1
        } else {
          column = column + 1
        }
      }
    } else if just_closed_quote {
      if ch == options.delimiter {
        current_row.push(field.to_string())
        field = StringBuilder()
        just_closed_quote = false
        at_field_start = true
        index = index + 1
        column = column + 1
      } else if ch == '\n' {
        current_row.push(field.to_string())
        field = StringBuilder()
        just_closed_quote = false
        at_field_start = true
        expected_columns = match
          finish_record(rows, current_row, expected_columns, options, line) {
          Ok(value) => value
          Err(err) => return Err(err)
        }
        current_row = []
        index = index + 1
        line = line + 1
        column = 1
      } else if ch == '\r' {
        current_row.push(field.to_string())
        field = StringBuilder()
        just_closed_quote = false
        at_field_start = true
        expected_columns = match
          finish_record(rows, current_row, expected_columns, options, line) {
          Ok(value) => value
          Err(err) => return Err(err)
        }
        current_row = []
        index = index + 1
        if index < total && chars[index] == '\n' {
          index = index + 1
        }
        line = line + 1
        column = 1
      } else {
        return error(
          @types.CsvErrorKind::UnexpectedCharacterAfterQuote,
          line,
          column,
          "expected a delimiter or a record ending after the closing quote",
        )
      }
    } else if ch == options.delimiter {
      current_row.push(field.to_string())
      field = StringBuilder()
      at_field_start = true
      index = index + 1
      column = column + 1
    } else if ch == '\n' {
      current_row.push(field.to_string())
      field = StringBuilder()
      at_field_start = true
      expected_columns = match
        finish_record(rows, current_row, expected_columns, options, line) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      current_row = []
      index = index + 1
      line = line + 1
      column = 1
    } else if ch == '\r' {
      current_row.push(field.to_string())
      field = StringBuilder()
      at_field_start = true
      expected_columns = match
        finish_record(rows, current_row, expected_columns, options, line) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      current_row = []
      index = index + 1
      if index < total && chars[index] == '\n' {
        index = index + 1
      }
      line = line + 1
      column = 1
    } else if ch == '"' {
      if at_field_start {
        in_quotes = true
        at_field_start = false
        index = index + 1
        column = column + 1
      } else {
        return error(
          @types.CsvErrorKind::UnexpectedQuote,
          line,
          column,
          "a quote may only appear at the start of a field",
        )
      }
    } else {
      field.write_char(ch)
      at_field_start = false
      index = index + 1
      column = column + 1
    }
  }

  if in_quotes {
    return error(
      @types.CsvErrorKind::UnclosedQuote,
      line,
      column,
      "reached the end of input before the quoted field was closed",
    )
  }

  if current_row.is_empty() &&
    field.to_string() == "" &&
    at_field_start &&
    !just_closed_quote {
    return Ok(rows)
  }

  current_row.push(field.to_string())
  match finish_record(rows, current_row, expected_columns, options, line) {
    Ok(_) => Ok(rows)
    Err(err) => Err(err)
  }
}

///|
pub fn parse_rows(input : String) -> @types.CsvRows {
  match parse_rows_result(input, @types.default_parse_options()) {
    Ok(rows) => rows
    Err(err) => @abort.abort(err.to_string())
  }
}
