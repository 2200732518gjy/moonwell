///|
test "metadata roundtrip injection and duplicate mnemonics are rejected" {
  let c = fixture().curves
  let bad = Header::{
    name: "WELL",
    unit: "",
    value: "abc : injected",
    description: "",
  }
  assert_true(rejected(() => make_log(c, [], headers=[bad])))
  let h = Header::{ name: "WELL", unit: "", value: "abc", description: "", }
  assert_true(rejected(() => make_log(c, [], headers=[h, h])))
  assert_true(rejected(() => make_log(c, [], parameters=[h, h])))
}

///|
test "nonzero LAS STEP must match every ASCII increment" {
  let text = sample_text("NO", "0 10\n1.5 20\n2 30\n")
  assert_true(rejected(() => parse(text)))
  let irregular = make_log(fixture().curves, [
    [Some(0.0), Some(10.0)],
    [Some(1.5), Some(20.0)],
    [Some(2.0), Some(30.0)],
  ])
  assert_eq(parse(write_las(irregular)).rows, irregular.rows)
}

///|
test "JSON nesting bound ignores escaped string brackets" {
  assert_true(
    execute("{\"command\":\"[[[\\\"}}\"}").contains("unknown command"),
  )
  let mut text = "0"
  for _ in 0..<33 {
    text = "[" + text + "]"
  }
  assert_true(
    try {
      ignore(read_report(text))
      false
    } catch {
      _ => true
    },
  )
}
