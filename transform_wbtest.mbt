///|
test "explicit transformations retain nulls and independent storage" {
  let log = fixture()
  assert_eq(affine_curve(log, "GR", 2.0, 1.0).rows[2][1], Some(61.0))
  assert_eq(mask_range(log, "GR", 15.0, 40.0).rows[0][1], None)
  assert_eq(rename_curve(log, "GR", "GAMMA").curves[1].name, "GAMMA")
  let derived = append_curve(
    log,
    { name: "FLAG", unit: "", description: "quality flag", api_code: "", },
    [Some(0.0), Some(1.0), Some(0.0)],
  )
  assert_eq(derived.rows[1][2], Some(1.0))
  assert_eq(log.curves.length(), 2)
}

///|
test "transformations reject ambiguous metadata and unsafe depth changes" {
  assert_true(rejected(() => rename_curve(fixture(), "GR", "dept")))
  assert_true(rejected(() => affine_curve(fixture(), "DEPT", 2.0, 0.0)))
  assert_true(rejected(() => mask_range(fixture(), "DEPT", 0.0, 1.0)))
  assert_true(
    rejected(() => {
      append_curve(
        fixture(),
        { name: "X", unit: "", description: "", api_code: "", },
        [],
      )
    }),
  )
}
