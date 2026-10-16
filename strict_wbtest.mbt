///|
fn strict_fixture() -> String {
  ("~V\nVERS. 2.0 : version\nWRAP. NO : wrap\n~W\n" +
  "STRT.M 0 : start\nSTOP.M 2 : stop\nSTEP.M 1 : step\nNULL. -999.25 : null\n" +
  "COMP. : company\nWELL. SYN:CASE : well\nFLD. : field\nLOC. : location\n" +
  "PROV. : province\nSRVC. : service\nDATE. : date\nUWI. : identifier\n" +
  "~C\nDEPT.M : depth\nGR.GAPI 07 010 01 00 : gamma\n~A\n0 10\n1 -999.25\n2 30\n")
  .split("\n")
  .join("\r\n")
}

///|
fn strict_has(text : String, field : String) -> Bool raise WellError {
  check_las2(read_las_document(text)).any(d => d.field == field)
}

///|
test "strict baseline passes complete well headers and opaque API codes" {
  let text = strict_fixture()
  let d = read_las_document(text)
  assert_eq(check_las2(d).length(), 0)
  assert_eq(document_text(d), text)
  assert_eq(document_to_log(d).curves[1].api_code, "07 010 01 00")
  assert_eq(
    check_las2(read_las_document(write_las_strict(parse_strict(text)))).length(),
    0,
  )
}

///|
test "strict required headers distinguish absent and empty" {
  for
    name in [
      "COMP", "WELL", "FLD", "LOC", "SRVC", "DATE", "STRT", "STOP", "STEP", "NULL",
    ] {
    let lines = strict_fixture()
      .split("\r\n")
      .filter(l => !l.has_prefix(name + "."))
      .to_array()
    assert_true(strict_has(lines.join("\r\n"), name))
  }
  assert_eq(check_las2(read_las_document(strict_fixture())).length(), 0)
}

///|
test "strict regional replacements and empty identifiers are legal" {
  let text = strict_fixture()
    .replace(
      old="PROV. : province",
      new="CNTY. : county\r\nSTAT. : state\r\nCTRY. : country",
    )
    .replace(old="UWI. : identifier", new="API. : identifier")
  assert_eq(check_las2(read_las_document(text)).length(), 0)
  assert_true(
    strict_has(text.replace(old="CTRY. : country\r\n", new=""), "CTRY"),
  )
  assert_true(
    strict_has(text.replace(old="API. : identifier\r\n", new=""), "UWI/API"),
  )
}

///|
test "source document preserves duplicates comments blank lines and exact newlines" {
  let text = strict_fixture().replace(
    old="~A",
    new="# keep trailing spaces  \r\n~P\r\nX. 1 : first\r\nX. 2 : second\r\n\r\n~Z customer\r\n# private opaque comment\r\n  opaque payload  \r\n\r\n~A",
  )
  let doc = read_las_document(text)
  assert_eq(check_las2(doc).length(), 0)
  assert_eq(document_text(doc), text)
  assert_eq(document_entries(doc).filter(e => e.section == "P").length(), 2)
  let limited = try {
    ignore(document_to_log(doc))
    false
  } catch {
    WellError(m) => m.has_prefix("model:")
  }
  assert_true(limited)
  assert_eq(document_text(doc), text)
}

///|
test "duplicate curve names are document-valid but model-limited" {
  let text = strict_fixture().replace(old="GR.GAPI", new="DEPT.GAPI")
  let doc = read_las_document(text)
  assert_eq(check_las2(doc).length(), 0)
  let limited = try {
    ignore(document_to_log(doc))
    false
  } catch {
    WellError(m) => m.has_prefix("model:")
  }
  assert_true(limited)
}

///|
test "decimal checks reject tiny interval differences hidden by Double tolerance" {
  let text = strict_fixture().replace(
    old="1 -999.25",
    new="1.00000000000000000000001 -999.25",
  )
  assert_true(strict_has(text, "STEP"))
  assert_true(
    strict_has(
      strict_fixture().replace(
        old="STOP.M 2",
        new="STOP.M 2.000000000000000000001",
      ),
      "STOP",
    ),
  )
}

///|
test "decimal endpoint scale and sign are exact not textual" {
  let text = strict_fixture()
    .replace(old="STRT.M 0", new="STRT.M -0.000")
    .replace(old="STOP.M 2", new="STOP.M +2.0000")
    .replace(old="STEP.M 1", new="STEP.M 1.00")
  assert_eq(check_las2(read_las_document(text)).length(), 0)
}

///|
test "off-grid constant STEP endpoints are rejected without data repair" {
  let text = strict_fixture()
    .replace(old="STRT.M 0", new="STRT.M 0.25")
    .replace(old="STOP.M 2", new="STOP.M 1.25")
    .replace(old="STEP.M 1", new="STEP.M 0.5")
    .replace(old="0 10", new="0.25 10")
    .replace(old="1 -999.25", new="0.75 -999.25")
    .replace(old="2 30", new="1.25 30")
  assert_true(strict_has(text, "STRT/STEP"))
  assert_true(strict_has(text, "STOP/STEP"))
  assert_true(rejected(() => parse_strict(text)))
}

///|
test "zero step permits genuinely irregular monotonic indexes" {
  let text = strict_fixture()
    .replace(old="STEP.M 1", new="STEP.M 0")
    .replace(old="1 -999.25", new="0.3 -999.25")
  assert_eq(check_las2(read_las_document(text)).length(), 0)
  assert_eq(
    check_las2(read_las_document(write_las_strict(parse_strict(text)))).length(),
    0,
  )
}

///|
test "depth and time index rules and units are checked independently of Log" {
  let base = strict_fixture()
  assert_true(strict_has(base.replace(old="DEPT.M", new="INDEX.M"), "INDEX"))
  assert_true(strict_has(base.replace(old="DEPT.M", new="DEPT.CM"), "unit"))
  for unit in ["M", "F", "FT"] {
    let t = base.split(".M").join("." + unit)
    assert_eq(check_las2(read_las_document(t)).length(), 0)
  }
  let time = base.split(".M").join(".S").replace(old="DEPT.S", new="TIME.S")
  assert_eq(check_las2(read_las_document(time)).length(), 0)
  let down = time
    .replace(old="STRT.S 0", new="STRT.S 2")
    .replace(old="STOP.S 2", new="STOP.S 0")
    .replace(old="STEP.S 1", new="STEP.S -1")
    .replace(old="0 10", new="2 10")
    .replace(old="2 30", new="0 30")
  assert_true(strict_has(down, "TIME"))
  assert_eq(
    check_las2(
      read_las_document(
        down.replace(old="TIME.S", new="DEPTH.FT").split(".S").join(".FT"),
      ),
    ).length(),
    0,
  )
}

///|
test "strict encoding CRLF and forbidden controls have line diagnostics" {
  assert_true(strict_has(strict_fixture().split("\r\n").join("\n"), "CRLF"))
  for c in ["\t", "茅", "\u0000", "\r"] {
    assert_true(
      strict_has(
        strict_fixture().replace(old="SYN:CASE", new="SYN" + c + "CASE"),
        "ASCII",
      ),
    )
  }
  let no_final_ending = strict_fixture().trim_end().to_owned()
  assert_eq(check_las2(read_las_document(no_final_ending)).length(), 0)
}

///|
test "ASCII blanks comments exponent and malformed decimal tokens are rejected" {
  for t in ["\r\n1 -999.25", "# forbidden\r\n1 -999.25"] {
    assert_true(
      strict_has(strict_fixture().replace(old="1 -999.25", new=t), "record"),
    )
  }
  for n in ["1e0", "NaN", "1,0", "--1", "1.2.3", "+", "."] {
    assert_true(
      strict_has(
        strict_fixture().replace(old="1 -999.25", new=n + " -999.25"),
        "DEPT",
      ),
    )
  }
  assert_true(
    strict_has(
      strict_fixture().replace(old="STEP.M 1", new="STEP.M 1e0"),
      "STEP",
    ),
  )
}

///|
test "strict wrapped layout and physical padding width" {
  let wrapped = strict_fixture()
    .replace(old="WRAP. NO", new="WRAP. YES")
    .replace(old="0 10", new="0\r\n10")
    .replace(old="1 -999.25", new="1\r\n-999.25")
    .replace(old="2 30", new="2\r\n30")
  assert_eq(check_las2(read_las_document(wrapped)).length(), 0)
  assert_true(strict_has(wrapped.replace(old="0\r\n10", new="0 10"), "index"))
  let spaces = StringBuilder()
  for _ in 0..<80 {
    spaces.write_char(' ')
  }
  assert_true(
    strict_has(
      wrapped.replace(
        old="\r\n10\r\n",
        new="\r\n" + spaces.to_string() + "10\r\n",
      ),
      "line",
    ),
  )
  assert_true(strict_has(wrapped.replace(old="2\r\n30", new="2"), "record"))
}

///|
test "sections and required versions cannot be ambiguous" {
  assert_true(
    strict_has(strict_fixture().replace(old="~V", new="~W"), "section"),
  )
  assert_true(
    strict_has(strict_fixture().replace(old="~A", new="~C\r\n~A"), "section"),
  )
  assert_true(strict_has(strict_fixture() + "~O\r\ntext\r\n", "section"))
  assert_true(
    strict_has(
      strict_fixture().replace(old="~W", new="VERS. 2.0 : duplicate\r\n~W"),
      "VERS",
    ),
  )
  assert_true(
    strict_has(
      strict_fixture().replace(old="VERS. 2.0", new="VERS.M 2.0"),
      "VERS",
    ),
  )
}

///|
test "strict writer expands extreme exponents and remains round-trippable" {
  for v in [1.0e-100, -1.0e100, 1.7976931348623157e308, 5.0e-324] {
    let text = las_decimal_text(v)
    assert_true(!text.to_upper().contains("E"))
    assert_true(decimal_grammar(text))
    assert_eq(parse_number(text), v)
    let log = parse_strict(strict_fixture())
    log.rows[0][1] = Some(v)
    let output = write_las_strict(log)
    assert_eq(check_las2(read_las_document(output)).length(), 0)
    assert_eq(parse_strict(output).rows[0][1], Some(v))
  }
}

///|
test "standard-valid extreme samples need not fit finite Double model" {
  let huge = StringBuilder()
  for _ in 0..<400 {
    huge.write_char('9')
  }
  let doc = read_las_document(
    strict_fixture().replace(old="0 10", new="0 " + huge.to_string()),
  )
  assert_eq(check_las2(doc).length(), 0)
  let limited = try {
    ignore(document_to_log(doc))
    false
  } catch {
    WellError(m) => m.has_prefix("model:")
  }
  assert_true(limited)
}

///|
test "strict serialization refuses missing metadata instead of inventing it" {
  assert_true(
    rejected(() => {
      ignore(write_las_strict(fixture()))
      fixture()
    }),
  )
  let log = parse_strict(strict_fixture())
  assert_eq(
    check_las2(read_las_document(write_las_strict(log, wrapped=true))).length(),
    0,
  )
}

///|
test "numeric budget is resource limitation not standard illegality" {
  let huge = StringBuilder()
  for _ in 0..<1025 {
    huge.write_char('9')
  }
  let doc = read_las_document(
    strict_fixture().replace(old="0 10", new="0 " + huge.to_string()),
  )
  let errors = check_las2(doc)
  assert_true(errors.any(d => d.kind == "resource"))
  assert_eq(
    document_text(doc),
    strict_fixture().replace(old="0 10", new="0 " + huge.to_string()),
  )
}

///|
test "model conversion refuses underflow and false NULL collisions" {
  let zeros = StringBuilder()
  for _ in 0..<400 {
    zeros.write_char('0')
  }
  let tiny = "0." + zeros.to_string() + "1"
  let text = strict_fixture().replace(old="0 10", new="0 " + tiny)
  assert_eq(check_las2(read_las_document(text)).length(), 0)
  let limited = try {
    ignore(parse_strict(text))
    false
  } catch {
    WellError(m) => m.has_prefix("model:")
  }
  assert_true(limited)
  let near_null = strict_fixture().replace(
    old="0 10",
    new="0 -999.25000000000000000000001",
  )
  assert_eq(check_las2(read_las_document(near_null)).length(), 0)
  let collision = try {
    ignore(parse_strict(near_null))
    false
  } catch {
    WellError(m) => m.has_prefix("model:")
  }
  assert_true(collision)
}
