///|
test "CSV quotes metadata, retains null cells and records provenance" {
  assert_eq(
    write_csv(fixture(), include_units=false),
    "\"DEPT\",\"GR\"\r\n0,10\r\n1,\r\n2,30\r\n",
  )
  assert_eq(csv_field("a\"b"), "\"a\"\"b\"")
  let result = assemble([fixture()], ["run\"one"], [0.0, 1.0, 2.0], 2.0, Reject)
  let output = provenance_csv(result)
  assert_true(output.contains("\"run\"\"one\""))
  assert_true(!output.contains("1,\"GR\""))
}

///|
test "provenance writers reject mutated source arrays" {
  let result = assemble([fixture()], ["A"], [0.0], 1.0, Reject)
  result.sources[0][1] = None
  assert_true(
    try {
      ignore(provenance_csv(result))
      false
    } catch {
      _ => true
    },
  )
}
