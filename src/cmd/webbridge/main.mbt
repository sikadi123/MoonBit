///|
fn delimiter_from_string(value : String) -> Char {
  if value.is_empty() {
    ','
  } else if value == "tab" || value == "\\t" {
    '\t'
  } else if value == ";" {
    ';'
  } else if value == "|" {
    '|'
  } else {
    ','
  }
}

///|
#cfg(target="js")
extern "js" fn bridge_csv_text() -> String =
  #| function() {
  #|   const state = globalThis.__moonbitCsvBridgeInput ?? {};
  #|   return typeof state.csvText === "string" ? state.csvText : "";
  #| }

///|
#cfg(not(target="js"))
fn bridge_csv_text() -> String {
  ""
}

///|
#cfg(target="js")
extern "js" fn bridge_delimiter() -> String =
  #| function() {
  #|   const state = globalThis.__moonbitCsvBridgeInput ?? {};
  #|   return typeof state.delimiter === "string" ? state.delimiter : ",";
  #| }

///|
#cfg(not(target="js"))
fn bridge_delimiter() -> String {
  ","
}

///|
#cfg(target="js")
extern "js" fn bridge_strict_column_count() -> Bool =
  #| function() {
  #|   const state = globalThis.__moonbitCsvBridgeInput ?? {};
  #|   return Boolean(state.strictColumnCount);
  #| }

///|
#cfg(not(target="js"))
fn bridge_strict_column_count() -> Bool {
  false
}

///|
#cfg(target="js")
extern "js" fn bridge_required_headers() -> Array[String] =
  #| function() {
  #|   const state = globalThis.__moonbitCsvBridgeInput ?? {};
  #|   return Array.isArray(state.requiredHeaders)
  #|     ? state.requiredHeaders.map(item => String(item))
  #|     : [];
  #| }

///|
#cfg(not(target="js"))
fn bridge_required_headers() -> Array[String] {
  []
}

///|
#cfg(target="js")
extern "js" fn bridge_selected_columns() -> Array[String] =
  #| function() {
  #|   const state = globalThis.__moonbitCsvBridgeInput ?? {};
  #|   return Array.isArray(state.selectedColumns)
  #|     ? state.selectedColumns.map(item => String(item))
  #|     : [];
  #| }

///|
#cfg(not(target="js"))
fn bridge_selected_columns() -> Array[String] {
  []
}

///|
#cfg(target="js")
extern "js" fn bridge_preview_limit() -> Int =
  #| function() {
  #|   const state = globalThis.__moonbitCsvBridgeInput ?? {};
  #|   return Number.isInteger(state.previewLimit) ? state.previewLimit : 5;
  #| }

///|
#cfg(not(target="js"))
fn bridge_preview_limit() -> Int {
  5
}

///|
#cfg(target="js")
extern "js" fn write_bridge_output(value : String) -> Unit =
  #| function(value) {
  #|   globalThis.__moonbitCsvBridgeOutput = value;
  #| }

///|
#cfg(not(target="js"))
fn write_bridge_output(_value : String) -> Unit {
  ()
}

///|
fn main {
  let response = @support.inspect_text(
    bridge_csv_text(),
    delimiter_from_string(bridge_delimiter()),
    bridge_strict_column_count(),
    bridge_required_headers(),
    bridge_selected_columns(),
    bridge_preview_limit(),
  )
  write_bridge_output(response.to_json().stringify(escape_slash=true))
}
