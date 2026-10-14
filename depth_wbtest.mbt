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
