///|
pub type CsvRows = @types.CsvRows

///|
pub type CsvTable = @types.CsvTable

///|
pub type CsvField = @types.CsvField

///|
pub type CsvRecord = @types.CsvRecord

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
pub fn to_table(rows : CsvRows) -> CsvTable {
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
    Ok(rows) => Ok(to_table(rows))
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
pub fn row_count(table : CsvTable) -> Int {
  table.rows.length()
}

///|
pub fn column_count(table : CsvTable) -> Int {
  table.header.length()
}

///|
pub fn has_header(table : CsvTable, name : String) -> Bool {
  match header_index(table, name) {
    Some(_) => true
    None => false
  }
}

///|
pub fn missing_headers(
  table : CsvTable,
  required : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for name in required {
    if !has_header(table, name) {
      missing.push(name)
    }
  }
  missing
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
fn row_field_value(row : Array[String], column_index : Int) -> String {
  if column_index < row.length() {
    row[column_index]
  } else {
    ""
  }
}

///|
pub fn record(table : CsvTable, row_index : Int) -> CsvRecord? {
  if row_index < 0 || row_index >= table.rows.length() {
    return None
  }

  let row = table.rows[row_index]
  let output : CsvRecord = []
  for column_index in 0..<table.header.length() {
    output.push({
      name: table.header[column_index],
      value: row_field_value(row, column_index),
    })
  }
  Some(output)
}

///|
pub fn records(table : CsvTable) -> Array[CsvRecord] {
  let output : Array[CsvRecord] = []
  for row_index in 0..<table.rows.length() {
    match record(table, row_index) {
      Some(item) => output.push(item)
      None => ()
    }
  }
  output
}

///|
pub fn column_values(table : CsvTable, column_name : String) -> Array[String]? {
  match header_index(table, column_name) {
    Some(column_index) => {
      let values : Array[String] = []
      for row in table.rows {
        values.push(row_field_value(row, column_index))
      }
      Some(values)
    }
    None => None
  }
}

///|
pub fn select_columns(
  table : CsvTable,
  columns : Array[String],
) -> Result[CsvTable, Array[String]] {
  let missing = missing_headers(table, columns)
  if !missing.is_empty() {
    return Err(missing)
  }

  let header : Array[String] = []
  let indexes : Array[Int] = []
  for name in columns {
    match header_index(table, name) {
      Some(index) => {
        header.push(name)
        indexes.push(index)
      }
      None => ()
    }
  }

  let rows : CsvRows = []
  for row in table.rows {
    let next_row : Array[String] = []
    for column_index in indexes {
      next_row.push(row_field_value(row, column_index))
    }
    rows.push(next_row)
  }
  Ok({ header, rows })
}

///|
pub fn from_table(table : CsvTable) -> CsvRows {
  if table.header.is_empty() {
    return table.rows
  }

  let rows : CsvRows = [table.header]
  for row in table.rows {
    rows.push(row)
  }
  rows
}

///|
pub fn stringify(rows : CsvRows) -> String {
  @writer.write_rows(rows)
}

///|
pub fn stringify_with(rows : CsvRows, options : WriteOptions) -> String {
  @writer.write_rows_with(rows, options)
}

///|
pub fn stringify_table(table : CsvTable) -> String {
  stringify(from_table(table))
}

///|
pub fn stringify_table_with(table : CsvTable, options : WriteOptions) -> String {
  stringify_with(from_table(table), options)
}
