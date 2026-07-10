///|
pub(all) struct CsvInspection {
  delimiter : String
  strict_column_count : Bool
  header : Array[String]
  row_count : Int
  column_count : Int
  preview_rows : @csv.CsvRows
  preview_records : Array[@csv.CsvRecord]
  required_headers : Array[String]
  missing_required_headers : Array[String]
  selected_columns : Array[String]
  selected_missing_headers : Array[String]
  selected_table : @csv.CsvTable?
  csv_text : String
  selected_csv_text : String?
} derive(ToJson, @debug.Debug)

///|
pub(all) struct CsvAnalysisResponse {
  ok : Bool
  message : String?
  inspection : CsvInspection?
  error : @csv.CsvError?
} derive(ToJson, @debug.Debug)

///|
fn preview_rows(rows : @csv.CsvRows, limit : Int) -> @csv.CsvRows {
  let size = if limit < 0 { 0 } else { limit }
  let output : @csv.CsvRows = []
  for index in 0..<rows.length() {
    if index >= size {
      break
    }
    output.push(rows[index])
  }
  output
}

///|
fn preview_records(table : @csv.CsvTable, limit : Int) -> Array[@csv.CsvRecord] {
  let output : Array[@csv.CsvRecord] = []
  let size = if limit < 0 { 0 } else { limit }
  for index in 0..<table.rows.length() {
    if index >= size {
      break
    }
    match @csv.record(table, index) {
      Some(item) => output.push(item)
      None => ()
    }
  }
  output
}

///|
fn delimiter_string(delimiter : Char) -> String {
  "\{delimiter}"
}

///|
fn build_inspection(
  table : @csv.CsvTable,
  delimiter : Char,
  strict_column_count : Bool,
  required_headers : Array[String],
  selected_columns : Array[String],
  preview_limit : Int,
) -> CsvInspection {
  let missing_required_headers = @csv.missing_headers(table, required_headers)
  let selected_missing_headers = @csv.missing_headers(table, selected_columns)
  let selected_table = if selected_columns.is_empty() ||
    !selected_missing_headers.is_empty() {
    None
  } else {
    match @csv.select_columns(table, selected_columns) {
      Ok(value) => Some(value)
      Err(_) => None
    }
  }
  let csv_text = @csv.stringify_table(table)
  let selected_csv_text = match selected_table {
    Some(value) => Some(@csv.stringify_table(value))
    None => None
  }
  {
    delimiter: delimiter_string(delimiter),
    strict_column_count,
    header: table.header,
    row_count: @csv.row_count(table),
    column_count: @csv.column_count(table),
    preview_rows: preview_rows(table.rows, preview_limit),
    preview_records: preview_records(table, preview_limit),
    required_headers,
    missing_required_headers,
    selected_columns,
    selected_missing_headers,
    selected_table,
    csv_text,
    selected_csv_text,
  }
}

///|
pub fn inspect_text(
  input : String,
  delimiter : Char,
  strict_column_count : Bool,
  required_headers : Array[String],
  selected_columns : Array[String],
  preview_limit : Int,
) -> CsvAnalysisResponse {
  let options : @csv.ParseOptions = { delimiter, strict_column_count }
  match @csv.parse_table_with_result(input, options) {
    Ok(table) => {
      let inspection = build_inspection(
        table, delimiter, strict_column_count, required_headers, selected_columns,
        preview_limit,
      )
      { ok: true, message: None, inspection: Some(inspection), error: None }
    }
    Err(err) =>
      {
        ok: false,
        message: Some(err.to_string()),
        inspection: None,
        error: Some(err),
      }
  }
}
