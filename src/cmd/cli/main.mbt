///|
struct CliConfig {
  input_path : String?
  output_path : String?
  delimiter : Char
  strict_column_count : Bool
  required_headers : Array[String]
  selected_columns : Array[String]
  preview_limit : Int
  json_output : Bool
  help : Bool
}

///|
fn default_cli_config() -> CliConfig {
  {
    input_path: None,
    output_path: None,
    delimiter: ',',
    strict_column_count: false,
    required_headers: [],
    selected_columns: [],
    preview_limit: 5,
    json_output: false,
    help: false,
  }
}

///|
fn help_text() -> String {
  [
    "moonbit-csv CLI", "", "Usage:", "  moon run --target js src/cmd/cli -- --input sample.csv [options]",
    "", "Options:", "  --input <path>        Read CSV text from a file", "  --output <path>       Write normalized or selected CSV to a file",
    "  --delimiter <value>   One of: ,, ;, |, tab, comma, semicolon, pipe", "  --strict              Enable strict column count validation",
    "  --require <a,b,c>     Require headers to exist", "  --select <a,b,c>      Select a subset of columns",
    "  --preview <n>         Number of preview rows to include (default: 5)", "  --json                Print JSON output",
    "  --help, -h            Show this help message",
  ].join("\n")
}

///|
fn user_args(args : Array[String]) -> Array[String] {
  if args.length() <= 2 {
    return args
  }
  let output : Array[String] = []
  for index in 2..<args.length() {
    output.push(args[index])
  }
  output
}

///|
fn delimiter_from_string(value : String) -> Char? {
  match value.trim().to_owned() {
    "," => Some(',')
    "comma" => Some(',')
    ";" => Some(';')
    "semicolon" => Some(';')
    "|" => Some('|')
    "pipe" => Some('|')
    "tab" => Some('\t')
    "\\t" => Some('\t')
    _ => None
  }
}

///|
fn split_csv_names(value : String) -> Array[String] {
  let output : Array[String] = []
  for item in value.split(",") {
    let name = item.to_owned().trim().to_owned()
    if !name.is_empty() {
      output.push(name)
    }
  }
  output
}

///|
fn parse_positive_int(value : String) -> Int? {
  try {
    let parsed = @string.parse_int(value)
    if parsed < 0 {
      None
    } else {
      Some(parsed)
    }
  } catch {
    _ => None
  }
}

///|
fn parse_args(args : Array[String]) -> Result[CliConfig, String] {
  let argv = user_args(args)
  let mut config = default_cli_config()
  let mut index = 0
  while index < argv.length() {
    let arg = argv[index]
    if arg == "--help" || arg == "-h" {
      config = { ..config, help: true }
      index = index + 1
    } else if arg == "--strict" {
      config = { ..config, strict_column_count: true }
      index = index + 1
    } else if arg == "--json" {
      config = { ..config, json_output: true }
      index = index + 1
    } else if arg == "--input" {
      if index + 1 >= argv.length() {
        return Err("missing value for --input")
      }
      config = { ..config, input_path: Some(argv[index + 1]) }
      index = index + 2
    } else if arg == "--output" {
      if index + 1 >= argv.length() {
        return Err("missing value for --output")
      }
      config = { ..config, output_path: Some(argv[index + 1]) }
      index = index + 2
    } else if arg == "--delimiter" {
      if index + 1 >= argv.length() {
        return Err("missing value for --delimiter")
      }
      match delimiter_from_string(argv[index + 1]) {
        Some(value) => {
          config = { ..config, delimiter: value }
          index = index + 2
        }
        None => return Err("unsupported delimiter; use one of: ,, ;, |, tab")
      }
    } else if arg == "--require" {
      if index + 1 >= argv.length() {
        return Err("missing value for --require")
      }
      config = { ..config, required_headers: split_csv_names(argv[index + 1]) }
      index = index + 2
    } else if arg == "--select" {
      if index + 1 >= argv.length() {
        return Err("missing value for --select")
      }
      config = { ..config, selected_columns: split_csv_names(argv[index + 1]) }
      index = index + 2
    } else if arg == "--preview" {
      if index + 1 >= argv.length() {
        return Err("missing value for --preview")
      }
      match parse_positive_int(argv[index + 1]) {
        Some(value) => {
          config = { ..config, preview_limit: value }
          index = index + 2
        }
        None => return Err("--preview expects a non-negative integer")
      }
    } else {
      return Err("unknown argument: \{arg}")
    }
  }
  Ok(config)
}

///|
fn join_names(values : Array[String]) -> String {
  if values.is_empty() {
    "(none)"
  } else {
    values.join(", ")
  }
}

///|
fn bool_label(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn report_validation_error(response : @support.CsvAnalysisResponse) -> String? {
  match response.inspection {
    Some(inspection) => {
      let issues : Array[String] = []
      if !inspection.missing_required_headers.is_empty() {
        issues.push(
          "missing required headers: \{join_names(inspection.missing_required_headers)}",
        )
      }
      if !inspection.selected_missing_headers.is_empty() {
        issues.push(
          "missing selected headers: \{join_names(inspection.selected_missing_headers)}",
        )
      }
      if issues.is_empty() {
        None
      } else {
        Some(issues.join("; "))
      }
    }
    None => None
  }
}

///|
fn csv_output_text(inspection : @support.CsvInspection) -> String {
  match inspection.selected_csv_text {
    Some(value) => value
    None => inspection.csv_text
  }
}

///|
fn print_summary(
  config : CliConfig,
  response : @support.CsvAnalysisResponse,
) -> Unit {
  match response.inspection {
    Some(inspection) => {
      let input_label = match config.input_path {
        Some(path) => path
        None => "(none)"
      }
      println("input: \{input_label}")
      println("delimiter: \{inspection.delimiter}")
      println(
        "strict column count: \{bool_label(inspection.strict_column_count)}",
      )
      println(
        "rows: \{inspection.row_count}, columns: \{inspection.column_count}",
      )
      println("header: \{join_names(inspection.header)}")
      println("required headers: \{join_names(inspection.required_headers)}")
      println(
        "missing required headers: \{join_names(inspection.missing_required_headers)}",
      )
      println("selected columns: \{join_names(inspection.selected_columns)}")
      println(
        "missing selected headers: \{join_names(inspection.selected_missing_headers)}",
      )
      println("preview rows:")
      if inspection.preview_rows.is_empty() {
        println("  (empty)")
      } else {
        for row in inspection.preview_rows {
          let row_text = row.join(" | ")
          println("  - \{row_text}")
        }
      }
      match config.output_path {
        Some(path) => println("output file: \{path}")
        None => ()
      }
    }
    None => ()
  }
}

///|
#cfg(target="js")
extern "js" fn read_text_file(path : String) -> String? =
  #| function(path) {
  #|   try {
  #|     const fs = require("node:fs");
  #|     globalThis.__moonbitCsvCliFsError = null;
  #|     return fs.readFileSync(path, "utf8");
  #|   } catch (error) {
  #|     globalThis.__moonbitCsvCliFsError = String(error?.message ?? error);
  #|     return null;
  #|   }
  #| }

///|
#cfg(not(target="js"))
fn read_text_file(_path : String) -> String? {
  None
}

///|
#cfg(target="js")
extern "js" fn write_text_file(path : String, content : String) -> Bool =
  #| function(path, content) {
  #|   try {
  #|     const fs = require("node:fs");
  #|     fs.writeFileSync(path, content, "utf8");
  #|     globalThis.__moonbitCsvCliFsError = null;
  #|     return true;
  #|   } catch (error) {
  #|     globalThis.__moonbitCsvCliFsError = String(error?.message ?? error);
  #|     return false;
  #|   }
  #| }

///|
#cfg(not(target="js"))
fn write_text_file(_path : String, _content : String) -> Bool {
  false
}

///|
#cfg(target="js")
extern "js" fn last_fs_error() -> String? =
  #| function() {
  #|   return globalThis.__moonbitCsvCliFsError ?? null;
  #| }

///|
#cfg(not(target="js"))
fn last_fs_error() -> String? {
  Some("file system access is only available on the JS target")
}

///|
#cfg(target="js")
extern "js" fn set_exit_code(code : Int) -> Unit =
  #| function(code) {
  #|   if (typeof process !== "undefined") {
  #|     process.exitCode = code;
  #|   }
  #| }

///|
#cfg(not(target="js"))
fn set_exit_code(_code : Int) -> Unit {
  ()
}

///|
fn main {
  match parse_args(@env.args()) {
    Err(message) => {
      println("error: \{message}")
      println("")
      println(help_text())
      set_exit_code(1)
    }
    Ok(config) => {
      if config.help {
        println(help_text())
        return
      }
      let input_path = match config.input_path {
        Some(path) => path
        None => {
          println("error: --input is required")
          println("")
          println(help_text())
          set_exit_code(1)
          return
        }
      }
      match read_text_file(input_path) {
        Some(content) => {
          let response = @support.inspect_text(
            content,
            config.delimiter,
            config.strict_column_count,
            config.required_headers,
            config.selected_columns,
            config.preview_limit,
          )
          if config.json_output {
            println(response.to_json().stringify(escape_slash=true))
          } else if response.ok {
            print_summary(config, response)
          } else {
            let error_message = match response.message {
              Some(value) => value
              None => "analysis failed"
            }
            println("error: \{error_message}")
          }
          if response.ok {
            match report_validation_error(response) {
              Some(message) => {
                if !config.json_output {
                  println("validation error: \{message}")
                }
                set_exit_code(1)
              }
              None =>
                match config.output_path {
                  Some(path) =>
                    match response.inspection {
                      Some(inspection) =>
                        if !write_text_file(path, csv_output_text(inspection)) {
                          let write_error = match last_fs_error() {
                            Some(value) => value
                            None => "unknown write error"
                          }
                          println(
                            "error: failed to write output file: \{write_error}",
                          )
                          set_exit_code(1)
                        }
                      None => ()
                    }
                  _ => ()
                }
            }
          } else {
            set_exit_code(1)
          }
        }
        None => {
          let read_error = match last_fs_error() {
            Some(value) => value
            None => "unknown read error"
          }
          println("error: failed to read input file: \{read_error}")
          set_exit_code(1)
        }
      }
    }
  }
}
