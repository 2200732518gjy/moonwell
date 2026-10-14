///|
test "clipped depth weighted trapezoids have explicit coverage" {
  let log = make_log(fixture().curves, [
    [Some(0.0), Some(0.0)],
    [Some(2.0), Some(4.0)],
  ])
  let s = summarize_interval(log, "GR", 0.5, 1.5, 2.0)
  assert_eq(s.integral, 2.0)
  assert_eq(s.coverage, 1.0)
  assert_eq(s.weighted_mean, Some(2.0))
  let extended = summarize_interval(log, "GR", -1.0, 3.0, 2.0)
  assert_eq(extended.coverage, 0.5)
  assert_eq(extended.integral, 4.0)
}

///|
test "interval integration never crosses missing samples or excessive gaps" {
  let s = summarize_interval(fixture(), "GR", 0.0, 2.0, 2.0)
  assert_eq(s.covered, 0.0)
  assert_eq(s.weighted_mean, None)
  let log = fill_linear(fixture(), "GR", 2.0)
  assert_eq(summarize_interval(log, "GR", 0.0, 2.0, 0.5).segments, 0)
  assert_true(
    try {
      ignore(summarize_interval(log, "GR", 1.0, 1.0, 2.0))
      false
    } catch {
      _ => true
    },
  )
}
