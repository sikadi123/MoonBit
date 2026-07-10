///|
pub type CsvRows = @types.CsvRows

///|
pub type CsvTable = @types.CsvTable

///|
pub type CsvError = @types.CsvError

///|
pub type CsvErrorKind = @types.CsvErrorKind

///|
pub type ParseOptions = @types.ParseOptions

///|
pub type WriteOptions = @types.WriteOptions

///|
pub fn default_parse_options() -> ParseOptions {
  @types.default_parse_options()
}

///|
pub fn default_write_options() -> WriteOptions {
  @types.default_write_options()
}

///|
pub fn parse_result(input : String) -> Result[CsvRows, CsvError] {
  @parser.parse_rows_result(input, default_parse_options())
}

///|
pub fn parse_with_result(
  input : String,
  options : ParseOptions,
) -> Result[CsvRows, CsvError] {
  @parser.parse_rows_result(input, options)
}

///|
pub fn parse(input : String) -> CsvRows {
  @parser.parse_rows(input)
}

///|
pub fn parse_with(input : String, options : ParseOptions) -> CsvRows {
  match parse_with_result(input, options) {
    Ok(rows) => rows
    Err(err) => @abort.abort(err.to_string())
  }
}

///|
fn rows_to_table(rows : CsvRows) -> CsvTable {
  if rows.is_empty() {
    return { header: [], rows: [] }
  }

  let header = rows[0]
  let body : CsvRows = []
  for index in 1..<rows.length() {
    body.push(rows[index])
  }
  { header, rows: body }
}

///|
pub fn parse_table_result(input : String) -> Result[CsvTable, CsvError] {
  parse_table_with_result(input, default_parse_options())
}

///|
pub fn parse_table_with_result(
  input : String,
  options : ParseOptions,
) -> Result[CsvTable, CsvError] {
  match parse_with_result(input, options) {
    Ok(rows) => Ok(rows_to_table(rows))
    Err(err) => Err(err)
  }
}

///|
pub fn parse_table(input : String) -> CsvTable {
  parse_table_with(input, default_parse_options())
}

///|
pub fn parse_table_with(input : String, options : ParseOptions) -> CsvTable {
  match parse_table_with_result(input, options) {
    Ok(table) => table
    Err(err) => @abort.abort(err.to_string())
  }
}

///|
pub fn header_index(table : CsvTable, name : String) -> Int? {
  for index in 0..<table.header.length() {
    if table.header[index] == name {
      return Some(index)
    }
  }
  None
}

///|
pub fn get_cell(
  table : CsvTable,
  row_index : Int,
  column_name : String,
) -> String? {
  if row_index < 0 || row_index >= table.rows.length() {
    return None
  }

  match header_index(table, column_name) {
    Some(column_index) => {
      let row = table.rows[row_index]
      if column_index < row.length() {
        Some(row[column_index])
      } else {
        None
      }
    }
    None => None
  }
}

///|
pub fn stringify(rows : CsvRows) -> String {
  @writer.write_rows(rows)
}

///|
pub fn stringify_with(rows : CsvRows, options : WriteOptions) -> String {
  @writer.write_rows_with(rows, options)
}
