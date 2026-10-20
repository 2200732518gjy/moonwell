///|
test "depth views own rows, retain depth and preserve acquisition order" {
  let log = fixture()
  assert_eq(window(log, 0.5, 2.0).rows.length(), 2)
  assert_eq(select(log, []).curves.length(), 1)
  assert_true(rejected(() => select(log, ["GR", "gr"])))
  let reverse = make_log(log.curves, [log.rows[2], log.rows[1], log.rows[0]])
  assert_eq(ascending(reverse).rows, log.rows)
  let copy = ascending(log)
  copy.rows[0][1] = None
  assert_eq(log.rows[0][1], Some(10.0))
}

///|
test "grid budgets and floating precision are enforced" {
  assert_eq(depth_grid(0.0, 2.0, 0.5), [0.0, 0.5, 1.0, 1.5, 2.0])
  assert_true(
    try {
      ignore(depth_grid(0.0, 10.0, 1.0, limit=5))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(depth_grid(1.0e20, 1.0e20 + 65536.0, 1.0))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "singleton grid is valid at large finite offsets" {
  assert_eq(depth_grid(1.0e20, 1.0e20, 0.1), [1.0e20])
}

///|
test "grid budget counts generated samples not fractional endpoint" {
  assert_eq(depth_grid(0.0, 9.5, 1.0, limit=10), [
    0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0,
  ])
  assert_eq(depth_grid(0.0, 0.5, 1.0, limit=1), [0.0])
  assert_eq(depth_grid(0.0, 0.25, 0.1, limit=3).length(), 3)
  assert_eq(depth_grid(0.0, 99999.5, 1.0).length(), 100000)
  assert_true(
    try {
      ignore(depth_grid(0.0, 10.0, 1.0, limit=10))
      false
    } catch {
      WellError(_) => true
    },
  )
}
