///|
test "decode nulls, wrapped records and descending depth" {
  let log = parse(sample_text("NO", "0 10\n1 -999.25\n2 30\n"))
  assert_eq(log.rows, fixture().rows)
  assert_eq(
    parse(sample_text("YES", "0\n10\n1\n-999.25\n2\n30\n")).rows,
    log.rows,
  )
  let descending = make_log(log.curves, [
    [Some(2.0), Some(3.0)],
    [Some(1.0), None],
  ])
  assert_eq(depths(descending), [2.0, 1.0])
}

///|
test "reject corrupt ASCII and inconsistent endpoints" {
  assert_true(rejected(() => parse(sample_text("NO", "0 10 20\n"))))
  assert_true(rejected(() => parse(sample_text("YES", "0\n"))))
  assert_true(rejected(() => parse(sample_text("YES", "0 10\n"))))
  assert_true(rejected(() => parse(sample_text("NO", "0 10\n1 20\n"))))
  assert_true(rejected(() => parse(sample_text("NO", "0 NaN\n2 20\n"))))
}

///|
test "large finite endpoints cannot disable LAS consistency checks" {
  for sign in [1.0, -1.0] {
    for wrapped in [false, true] {
      let first = sign * 1.0e308
      let last = sign * 1.1e308
      let data = if wrapped {
        first.to_string() + "\n1\n" + last.to_string() + "\n-999.25\n"
      } else {
        first.to_string() + " 1\n" + last.to_string() + " -999.25\n"
      }
      let text = sample_text(if wrapped { "YES" } else { "NO" }, data)
        .replace(old="STRT.M 0", new="STRT.M " + first.to_string())
        .replace(old="STOP.M 2", new="STOP.M " + last.to_string())
        .replace(old="STEP.M 1", new="STEP.M 0")
      let expected = [[Some(first), Some(1.0)], [Some(last), None]]
      assert_eq(parse(text).rows, expected)
      for field in ["STRT", "STOP"] {
        let old_value = if field == "STRT" { first } else { last }
        let corrupt = text.replace(
          old=field + ".M " + old_value.to_string(),
          new=field + ".M 0",
        )
        assert_true(corrupt != text)
        assert_true(rejected(() => parse(corrupt)))
      }
      let close = text.replace(
        old="STRT.M " + first.to_string(),
        new="STRT.M " + (first + sign * 1.0e299).to_string(),
      )
      assert_eq(parse(close).rows, expected)
    }
  }
}
