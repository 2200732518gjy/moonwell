///|
fn api_text() -> String {
  sample_text("NO", "0 10\n1 -999.25\n2 30\n").replace(
    old="GR.GAPI : gamma",
    new="GR.GAPI 45 310 01 00 : gamma",
  )
}

///|
test "API code including leading zeros survives both LAS layouts" {
  let log = parse(api_text())
  assert_eq(log.curves[0].api_code, "")
  assert_eq(log.curves[1].api_code, "45 310 01 00")
  for wrapped in [false, true] {
    let output = write_las(log, wrapped~)
    assert_true(output.contains("GR.GAPI 45 310 01 00 : gamma"))
    let copy = parse(output)
    assert_eq(copy.curves[1].api_code, log.curves[1].api_code)
    assert_eq(copy.rows, log.rows)
  }
}

///|
test "opaque API codes are not converted to numbers or interpreted as samples" {
  let log = parse(api_text().replace(old="45 310 01 00", new="07 010 01 00"))
  assert_eq(log.curves[1].api_code, "07 010 01 00")
  assert_eq(log.rows[0][1], Some(10.0))
  assert_eq(parse(write_las(log)).curves[1].api_code, "07 010 01 00")
}

///|
test "API metadata follows selection rename resampling and dimensional conversion" {
  let log = parse(api_text())
  assert_eq(select(log, ["GR"]).curves[1].api_code, "45 310 01 00")
  assert_eq(rename_curve(log, "GR", "GAMMA").curves[1].api_code, "45 310 01 00")
  assert_eq(
    resample(log, [0.0, 0.5, 1.0], 2.0).curves[1].api_code,
    "45 310 01 00",
  )
  assert_eq(convert_curve(log, "DEPT", "FT").curves[1].api_code, "45 310 01 00")
  assert_eq(
    affine_curve(log, "GR", 2.0, 1.0).curves[1].api_code,
    "45 310 01 00",
  )
}

///|
test "assembly retains nonempty API code and rejects conflicting definitions" {
  let a = fixture()
  let b = parse(api_text())
  for runs in [[a, b], [b, a]] {
    let result = assemble(runs, ["a", "b"], [0.0, 1.0, 2.0], 2.0, PreferFirst)
    assert_eq(result.log.curves[1].api_code, "45 310 01 00")
  }
  let c = parse(api_text().replace(old="45 310 01 00", new="07 010 01 00"))
  let bad = try {
    ignore(assemble([b, c], ["b", "c"], [0.0], 2.0, PreferLast))
    false
  } catch {
    WellError(message) => {
      assert_true(message.contains("API codes"))
      true
    }
  }
  assert_true(bad)
}

///|
test "API metadata cannot inject lines and descriptions cannot steal the last colon" {
  for code in ["45\n~ASCII", " 45", "45\r", "45\t310"] {
    let curves = fixture().curves.copy()
    curves[1] = {
      name: "GR",
      unit: "GAPI",
      description: "gamma",
      api_code: code,
    }
    assert_true(rejected(() => make_log(curves, [])))
  }
  let curves = fixture().curves.copy()
  curves[1] = {
    name: "GR",
    unit: "GAPI",
    description: "gamma: ray",
    api_code: "",
  }
  assert_true(rejected(() => make_log(curves, [])))
}

///|
test "legal punctuation in curve mnemonic is accepted without alias inference" {
  let log = parse(api_text().replace(old="GR.GAPI", new="GR/RAW+.GAPI"))
  assert_eq(curve_index(log, "gr/raw+"), 1)
  assert_eq(parse(write_las(log)).curves[1].name, "GR/RAW+")
}

///|
test "colon-bearing well and parameter values roundtrip using final delimiter" {
  let text = api_text().replace(
    old="WELL. SYNTHETIC : well",
    new="WELL. SYN:TEST : well",
  )
  let log = parse(text)
  assert_eq(log.headers[4].value, "SYN:TEST")
  assert_eq(parse(write_las(log)).headers[4].value, "SYN:TEST")
}

///|
test "customer sections and extra version lines survive numerical transforms" {
  let text = api_text().replace(
    old="~Well",
    new="SOURCE. SYNTHETIC : producer\n~X Vendor metadata\n# preserved vendor comment\nopaque: value\n~Well",
  )
  let log = parse(text)
  assert_eq(log.version_headers[0].value, "SYNTHETIC")
  assert_eq(log.extra_sections[0].title, "~X Vendor metadata")
  assert_eq(log.extra_sections[0].lines.length(), 2)
  let copy = parse(write_las(convert_curve(ascending(log), "DEPT", "FT")))
  assert_eq(copy.version_headers[0].value, "SYNTHETIC")
  assert_eq(copy.extra_sections[0].lines, log.extra_sections[0].lines)
}

///|
test "customer sections cannot impersonate reserved sections or inject boundaries" {
  for
    section in [
      { title: "~Well", lines: [], },
      { title: "~X", lines: ["~ASCII"], },
      { title: "~X\n~ASCII", lines: [], },
    ] {
    assert_true(
      rejected(() => make_log(fixture().curves, [], extra_sections=[section])),
    )
  }
  assert_true(
    rejected(() => parse(api_text().replace(old="~Version", new="~Well"))),
  )
}

///|
test "customer metadata is an owned snapshot" {
  let lines = ["opaque"]
  let sections = [{ title: "~X", lines, }]
  let log = make_log(fixture().curves, fixture().rows, extra_sections=sections)
  lines[0] = "modified"
  sections.clear()
  assert_eq(log.extra_sections[0].lines[0], "opaque")
}

///|
test "wide wrapped records respect the 80 character physical limit including CRLF" {
  let curves = fixture().curves.copy()
  let row : Array[Double?] = [Some(0.0), Some(1.23456789012345)]
  for i in 2..<35 {
    curves.push({
      name: "C" + i.to_string(),
      unit: "V",
      api_code: "",
      description: "synthetic",
    })
    row.push(Some(1.23456789012345))
  }
  let log = make_log(curves, [row])
  let text = write_las(log, wrapped=true)
  let mut data = false
  let mut count = 0
  for line in text.split("\r\n") {
    if data && line != "" {
      assert_true(line.length() + 2 <= 80)
      count += 1
    }
    if line == "~ASCII" {
      data = true
    }
  }
  assert_true(count > 2)
  assert_eq(parse(text).rows, log.rows)
}

///|
test "TIME is a supported numeric index with ascending samples" {
  let text = api_text()
    .replace(old="DEPT.M", new="TIME.S")
    .replace(old="STRT.M", new="STRT.S")
    .replace(old="STOP.M", new="STOP.S")
    .replace(old="STEP.M", new="STEP.S")
  let log = parse(text)
  assert_eq(log.curves[0].name, "TIME")
  assert_eq(parse(write_las(log)).rows, log.rows)
}
