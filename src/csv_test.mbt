///|
test "parse empty input" {
  debug_inspect(
    parse(""),
    content=(
      #|[]
    ),
  )
}

///|
test "stringify empty rows" {
  debug_inspect(
    stringify([]),
    content=(
      #|""
    ),
  )
}
