///|
test "LAS writer roundtrips both layouts and irregular depth" {
  let log = fixture()
  assert_eq(parse(write_las(log)).rows, log.rows)
  assert_eq(parse(write_las(log, wrapped=true)).rows, log.rows)
  let irregular = make_log(log.curves, [
    [Some(4.0), None],
    [Some(2.0), Some(5.0)],
    [Some(1.0), Some(6.0)],
  ])
  assert_eq(parse(write_las(irregular)).rows, irregular.rows)
}

///|
test "writer refuses sentinel collisions and empty tables" {
  let bad = make_log(fixture().curves, [[Some(0.0), Some(-999.25)]])
  let rejects = try {
    ignore(write_las(bad))
    false
  } catch {
    _ => true
  }
  assert_true(rejects)
  let empty = try {
    ignore(write_las(make_log(fixture().curves, [])))
    false
  } catch {
    _ => true
  }
  assert_true(empty)
}
