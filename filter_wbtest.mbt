///|
test "median filtering is gap aware and does not use updated output" {
  let log = make_log(fixture().curves, [
    [Some(0.0), Some(1.0)],
    [Some(1.0), Some(100.0)],
    [Some(2.0), Some(2.0)],
    [Some(3.0), None],
    [Some(10.0), Some(9.0)],
  ])
  let filtered = median_filter(log, "GR", 1, 2.0)
  assert_eq(filtered.rows[1][1], Some(2.0))
  assert_eq(filtered.rows[3][1], None)
  assert_eq(filtered.rows[4][1], Some(9.0))
  assert_eq(log.rows[1][1], Some(100.0))
}

///|
test "derived gradient uses signed depth and refuses null crossings" {
  let log = fill_linear(fixture(), "GR", 2.0)
  let result = gradient_curve(log, "GR", "DGR", 2.0)
  assert_eq(result.rows[0][2], None)
  assert_eq(result.rows[1][2], Some(10.0))
  assert_eq(gradient_curve(fixture(), "GR", "DGR", 2.0).rows[2][2], None)
  assert_true(rejected(() => median_filter(log, "GR", 0, 2.0)))
}
