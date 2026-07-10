///|
pub type CsvRows = @types.CsvRows

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
pub fn stringify(rows : CsvRows) -> String {
  @writer.write_rows(rows)
}

///|
pub fn stringify_with(rows : CsvRows, options : WriteOptions) -> String {
  @writer.write_rows_with(rows, options)
}
