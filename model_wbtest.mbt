///|
fn fixture() -> Log raise WellError {
  make_log(
    [
      { name: "DEPT", unit: "M", description: "depth", api_code: "", },
      { name: "GR", unit: "GAPI", description: "gamma", api_code: "", },
    ],
    [[Some(0.0), Some(10.0)], [Some(1.0), None], [Some(2.0), Some(30.0)]],
  )
}

///|
fn rejected(f : () -> Log raise WellError) -> Bool {
  try {
    ignore(f())
    false
  } catch {
    _ => true
  }
}

///|
test "model snapshots input and resolves mnemonics" {
  let data = [[Some(0.0), Some(1.0)]]
  let log = make_log(fixture().curves, data)
  data[0][1] = Some(8.0)
  assert_eq(log.rows[0][1], Some(1.0))
  assert_eq(curve_index(log, "gr"), 1)
  assert_eq(depths(fixture()), [0.0, 1.0, 2.0])
}

///|
test "model rejects invalid depth and dimensions" {
  assert_true(
    rejected(() => {
      make_log(fixture().curves, [[Some(1.0), None], [Some(1.0), None]])
    }),
  )
  assert_true(
    rejected(() => {
      make_log(fixture().curves, [
        [Some(0.0), None],
        [Some(2.0), None],
        [Some(1.0), None],
      ])
    }),
  )
  assert_true(rejected(() => make_log(fixture().curves, [[None, None]])))
  assert_true(rejected(() => make_log(fixture().curves, [[Some(1.0)]])))
}
