///|
pub fn parse(input : String) -> Array[Array[String]] {
  @parser.parse_rows(input)
}

///|
pub fn stringify(rows : Array[Array[String]]) -> String {
  @writer.write_rows(rows)
}
