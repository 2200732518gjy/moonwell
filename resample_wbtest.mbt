///|
test "interpolation never bridges null endpoints or extrapolates" {
  let log = fixture()
  assert_eq(sample(log, "GR", 0.0, 2.0), Some(10.0))
  assert_eq(sample(log, "GR", 0.5, 2.0), None)
  assert_eq(sample(log, "GR", 3.0, 2.0), None)
  let clean = make_log(log.curves, [
    [Some(0.0), Some(10.0)],
    [Some(2.0), Some(30.0)],
  ])
  assert_eq(sample(clean, "GR", 1.0, 2.0), Some(20.0))
  assert_eq(sample(clean, "GR", 1.0, 1.0), None)
  assert_eq(resample(clean, [0.0, 1.0, 2.0], 2.0).rows[1][1], Some(20.0))
}

///|
test "resampling rejects unsorted grids and owns output" {
  assert_true(rejected(() => resample(fixture(), [1.0, 0.0], 2.0)))
  assert_true(rejected(() => resample(fixture(), [0.0, 0.0], 2.0)))
  assert_true(rejected(() => resample(fixture(), [0.0], 0.0)))
  assert_eq(resample(fixture(), [], 1.0).rows.length(), 0)
}
