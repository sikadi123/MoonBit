///|
test "inspect_text returns summary and selected csv output" {
  let response = inspect_text(
    "name,lang,quote\nMoonBit,mbt,\"fast, simple, fun\"\nRust,rs,safe",
    ',',
    false,
    ["name", "lang"],
    ["name", "quote"],
    1,
  )
  @test.assert_eq(response.ok, true)
  match response.inspection {
    Some(inspection) => {
      @test.assert_eq(inspection.row_count, 2)
      @test.assert_eq(inspection.column_count, 3)
      @test.assert_eq(inspection.preview_rows, [
        ["MoonBit", "mbt", "fast, simple, fun"],
      ])
      @test.assert_eq(inspection.required_headers, ["name", "lang"])
      @test.assert_eq(inspection.missing_required_headers, [])
      @test.assert_eq(inspection.selected_columns, ["name", "quote"])
      @test.assert_eq(inspection.selected_missing_headers, [])
      @test.assert_eq(
        inspection.selected_csv_text,
        Some("name,quote\nMoonBit,\"fast, simple, fun\"\nRust,safe"),
      )
    }
    None => fail("expected inspection data")
  }
}

///|
test "inspect_text reports missing selected headers" {
  let response = inspect_text(
    "name,lang\nMoonBit,mbt",
    ',',
    false,
    ["name"],
    ["name", "quote"],
    3,
  )
  @test.assert_eq(response.ok, true)
  match response.inspection {
    Some(inspection) => {
      @test.assert_eq(inspection.missing_required_headers, [])
      @test.assert_eq(inspection.selected_missing_headers, ["quote"])
      @test.assert_eq(inspection.selected_table, None)
      @test.assert_eq(inspection.selected_csv_text, None)
    }
    None => fail("expected inspection data")
  }
}

///|
test "inspect_text clamps negative preview limit to empty preview" {
  let response = inspect_text(
    "name,lang\nMoonBit,mbt\nRust,rs",
    ',',
    false,
    [],
    [],
    -1,
  )
  @test.assert_eq(response.ok, true)
  match response.inspection {
    Some(inspection) => {
      @test.assert_eq(inspection.preview_rows, [])
      @test.assert_eq(inspection.preview_records, [])
    }
    None => fail("expected inspection data")
  }
}

///|
test "inspect_text returns parse errors for strict column mismatch" {
  let response = inspect_text("a,b\nc", ',', true, [], [], 5)
  @test.assert_eq(response.ok, false)
  match response.inspection {
    None => ()
    Some(_) => fail("did not expect inspection data")
  }
  match response.error {
    Some(err) => {
      @test.assert_eq(err.kind, @csv.CsvErrorKind::InconsistentColumnCount)
      @test.assert_eq(err.line, 2)
    }
    None => fail("expected parse error")
  }
}
