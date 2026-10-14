///|
test "QC thresholds missing and deterministic order" {
  let rules = [
    QcRule::{
      curve: "GR",
      minimum: Some(15.0),
      maximum: Some(25.0),
      max_gradient: Some(2.0),
      constant_run: 0,
    },
  ]
  let issues = quality_check(fixture(), rules, 0.5)
  assert_eq(issues.map(i => i.code), [
    "DEPTH_GAP", "DEPTH_GAP", "BELOW_MIN", "MISSING", "ABOVE_MAX",
  ])
  assert_eq(issues[2].row, 0)
}

///|
test "QC constant runs reset at null and gradients honor depth" {
  let log = make_log(fixture().curves, [
    [Some(0.0), Some(1.0)],
    [Some(1.0), Some(1.0)],
    [Some(2.0), None],
    [Some(3.0), Some(1.0)],
    [Some(4.0), Some(9.0)],
  ])
  let rule = QcRule::{
    curve: "GR",
    minimum: None,
    maximum: None,
    max_gradient: Some(4.0),
    constant_run: 2,
  }
  assert_eq(quality_check(log, [rule], 2.0).map(i => i.code), [
    "CONSTANT_RUN", "MISSING", "GRADIENT",
  ])
  assert_true(
    try {
      ignore(quality_check(log, [{ ..rule, constant_run: 1, }], 2.0))
      false
    } catch {
      _ => true
    },
  )
}
