///|
test "decimal grammar, exponent and overflow boundaries" {
  assert_eq(parse_number("-1.25e2"), -125.0)
  assert_eq(parse_number("+.5"), 0.5)
  assert_eq(parse_number("1."), 1.0)
  for text in ["NaN", "inf", "1e", "0x10", "1_2", "1,2", ".", "1e999"] {
    let bad = try {
      ignore(parse_number(text))
      false
    } catch {
      _ => true
    }
    assert_true(bad)
  }
}

///|
test "metadata preserves units and colons in description" {
  let h = parse_header("GR.GAPI : gamma: ray")
  assert_eq(h.name, "GR")
  assert_eq(h.unit, "GAPI")
  assert_eq(h.value, "")
  assert_eq(h.description, "gamma: ray")
  assert_eq(parse_header("NULL. -999.25 : sentinel").value, "-999.25")
  assert_eq(words(" 1\t2\r\n3 "), ["1", "2", "3"])
}
