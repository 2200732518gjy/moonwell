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
