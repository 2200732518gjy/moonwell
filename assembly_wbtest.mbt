///|
test "assembly reports conflicts and cell-level source decisions" {
  let a = make_log(fixture().curves, [
    [Some(0.0), Some(10.0)],
    [Some(2.0), Some(30.0)],
  ])
  let b = make_log(fixture().curves, [
    [Some(0.0), Some(11.0)],
    [Some(2.0), None],
  ])
  let result = assemble([a, b], ["A", "B"], [0.0, 1.0, 2.0], 2.0, PreferLast)
  assert_eq(result.log.rows[0][1], Some(11.0))
  assert_eq(result.log.rows[1][1], Some(20.0))
  assert_eq(result.sources[0][1].unwrap().run, 1)
  assert_true(result.sources[1][1].unwrap().interpolated)
  assert_eq(result.conflicts.length(), 1)
  assert_eq(result.conflicts[0].kept_run, 0)
  assert_true(
    try {
      ignore(assemble([a, b], ["A", "B"], [0.0], 2.0, Reject))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "assembly aligns feet depth and converts shared curve units" {
  let a = make_log(
    [
      { name: "DEPT", unit: "M", description: "", },
      { name: "SP", unit: "V", description: "", },
    ],
    [[Some(0.0), Some(1.0)], [Some(3.048), None]],
  )
  let b = make_log(
    [
      { name: "DEPTH", unit: "FT", description: "", },
      { name: "sp", unit: "MV", description: "", },
    ],
    [[Some(0.0), Some(1000.0)], [Some(10.0), Some(2000.0)]],
  )
  let merged = assemble([a, b], ["metric", "feet"], [0.0, 3.048], 4.0, Reject)
  assert_eq(merged.log.rows[1][1], Some(2.0))
  assert_eq(merged.conflicts.length(), 0)
  assert_eq(merged.sources[1][1].unwrap().run, 1)
  assert_true(
    try {
      ignore(assemble([a, b], ["x", "x"], [0.0], 4.0, Reject))
      false
    } catch {
      _ => true
    },
  )
}
