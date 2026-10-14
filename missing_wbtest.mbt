///|
test "bounded missing spans support constrained fill without mutation" {
  let log = fixture()
  let spans = missing_spans(log, "GR")
  assert_eq(spans.length(), 1)
  assert_eq(spans[0].first_row, 1)
  assert_true(spans[0].bounded)
  assert_eq(fill_linear(log, "GR", 2.0).rows[1][1], Some(20.0))
  assert_eq(fill_linear(log, "GR", 1.0).rows[1][1], None)
  assert_eq(log.rows[1][1], None)
  assert_eq(fill_constant(log, "GR", 0.0).rows[1][1], Some(0.0))
}

///|
test "edge missing runs remain missing under interpolation" {
  let log = make_log(fixture().curves, [
    [Some(0.0), None],
    [Some(1.0), Some(1.0)],
    [Some(2.0), None],
  ])
  assert_eq(missing_spans(log, "GR").length(), 2)
  assert_true(!missing_spans(log, "GR")[0].bounded)
  assert_eq(fill_linear(log, "GR", 4.0).rows, log.rows)
  assert_true(rejected(() => fill_constant(log, "DEPT", 1.0)))
}
