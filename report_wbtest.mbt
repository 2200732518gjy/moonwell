///|
test "quality report is valid JSON with deterministic versioned structure" {
  let report = quality_report(fixture(), [], 2.0)
  let text = report_text(report)
  assert_true(@json.valid(text))
  assert_true(text.contains("moonwell.qa/v1"))
  assert_true(text.contains("population_variance"))
  assert_eq(report_text(quality_report(fixture(), [], 2.0)), text)
}

///|
test "assembly reports preserve source shape and escaped names" {
  let a = assemble([fixture()], ["a\"b"], [0.0, 1.0], 2.0, Reject)
  let report = assembly_report(a)
  assert_true(@json.valid(report_text(report)))
  assert_true(report_text(report).contains("moonwell.assembly/v1"))
  assert_true(
    @json.valid(
      report_text(
        interval_report(summarize_interval(fixture(), "GR", 0.0, 2.0, 2.0)),
      ),
    ),
  )
}
