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

///|
test "gradient keeps finite slopes when sample differences overflow" {
  for descending in [false, true] {
    for negative in [false, true] {
      let rows = [
        [Some(0.0), Some(if negative { 1.0e308 } else { -1.0e308 })],
        [Some(1.0e308), Some(if negative { -1.0e308 } else { 1.0e308 })],
      ]
      let log = make_log(
        fixture().curves,
        if descending {
          [rows[1], rows[0]]
        } else {
          rows
        },
      )
      let result = gradient_curve(log, "GR", "DGR", 1.0e308)
      assert_eq(result.rows[0][2], None)
      assert_eq(result.rows[1][2], Some(if negative { -2.0 } else { 2.0 }))
      assert_eq(log.curves.length(), 2)
      assert_eq(log.rows[0].length(), 2)
      result.rows[0][1] = None
      assert_true(log.rows[0][1] is Some(_))
      assert_eq(gradient_curve(log, "GR", "DGR", 1.0e307).rows[1][2], None)
    }
  }
}

///|
test "gradient still rejects true result overflow and preserves zero or null slopes" {
  let large = make_log(fixture().curves, [
    [Some(0.0), Some(-1.0e308)],
    [Some(1.0), Some(1.0e308)],
  ])
  assert_true(rejected(() => gradient_curve(large, "GR", "DGR", 1.0)))
  let equal = make_log(fixture().curves, [
    [Some(0.0), Some(1.0e308)],
    [Some(0.5), Some(1.0e308)],
    [Some(1.0), None],
  ])
  let result = gradient_curve(equal, "GR", "DGR", 1.0)
  assert_eq(result.rows[1][2], Some(0.0))
  assert_eq(result.rows[2][2], None)
}
