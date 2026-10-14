///|
test "null-aware statistics and type seven quantiles" {
  let s = summarize(fixture(), "GR")
  assert_eq(s.present, 2)
  assert_eq(s.missing, 1)
  assert_true((s.mean.unwrap() - 20.0).abs() < 1.0e-10)
  assert_true((s.variance.unwrap() - 100.0).abs() < 1.0e-10)
  assert_eq(s.median, Some(20.0))
  assert_eq(quantile(fixture(), "GR", 0.25), Some(15.0))
  assert_eq(quantile(fixture(), "GR", 1.0), Some(30.0))
}

///|
test "all missing and singleton statistics are defined" {
  let empty = make_log(fixture().curves, [[Some(0.0), None]])
  assert_eq(summarize(empty, "GR").mean, None)
  assert_eq(summarize(empty, "DEPT").variance, Some(0.0))
  assert_eq(quantile(empty, "GR", 0.5), None)
  assert_true(
    try {
      ignore(quantile(empty, "GR", 1.1))
      false
    } catch {
      _ => true
    },
  )
}
