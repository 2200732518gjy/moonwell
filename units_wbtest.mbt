///|
test "unit conversion respects dimensions and affine offsets" {
  assert_eq(convert_value(10.0, "FT", "M"), 3.048)
  assert_true(convert_value(32.0, "DEGF", "DEGC").abs() < 1.0e-10)
  assert_eq(convert_value(2.0, "G/CC", "KG/M3"), 2000.0)
  assert_eq(convert_value(7.0, "GAPI", "gapi"), 7.0)
  assert_true(
    try {
      ignore(convert_value(1.0, "GAPI", "M"))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(convert_value(1.0, "M", "V"))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "curve conversions preserve nulls and produce roundtrippable headers" {
  let log = parse(sample_text("NO", "0 10\n1 -999.25\n2 30\n"))
  let feet = convert_curve(log, "DEPT", "FT")
  let meters = convert_curve(feet, "DEPT", "M")
  assert_true((meters.rows[2][0].unwrap() - 2.0).abs() < 1.0e-10)
  assert_eq(feet.rows[1][1], None)
  assert_eq(parse(write_las(feet)).curves[0].unit, "FT")
}
