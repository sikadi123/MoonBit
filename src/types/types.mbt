///|
pub type CsvRows = Array[Array[String]]

///|
pub(all) struct CsvField {
  name : String
  value : String
} derive(Eq, @debug.Debug)

///|
pub type CsvRecord = Array[CsvField]

///|
pub(all) struct CsvTable {
  header : Array[String]
  rows : CsvRows
} derive(Eq, @debug.Debug)

///|
pub(all) enum CsvErrorKind {
  UnclosedQuote
  UnexpectedQuote
  UnexpectedCharacterAfterQuote
  InconsistentColumnCount
} derive(Eq, @debug.Debug)

///|
pub(all) struct CsvError {
  kind : CsvErrorKind
  line : Int
  column : Int
  message : String
} derive(Eq, @debug.Debug)

///|
pub(all) struct ParseOptions {
  delimiter : Char
  strict_column_count : Bool
} derive(Eq, @debug.Debug)

///|
pub(all) struct WriteOptions {
  delimiter : Char
  line_ending : String
  always_quote : Bool
} derive(Eq, @debug.Debug)

///|
pub fn default_parse_options() -> ParseOptions {
  { delimiter: ',', strict_column_count: false }
}

///|
pub fn default_write_options() -> WriteOptions {
  { delimiter: ',', line_ending: "\n", always_quote: false }
}

///|
pub fn kind_to_string(kind : CsvErrorKind) -> String {
  match kind {
    UnclosedQuote => "UnclosedQuote"
    UnexpectedQuote => "UnexpectedQuote"
    UnexpectedCharacterAfterQuote => "UnexpectedCharacterAfterQuote"
    InconsistentColumnCount => "InconsistentColumnCount"
  }
}

///|
pub impl Show for CsvError with fn output(self, logger) {
  logger.write_string(
    "\{kind_to_string(self.kind)} at line \{self.line}, column \{self.column}: \{self.message}",
  )
}
