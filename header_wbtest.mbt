///|
fn sample_text(wrap : String, data : String) -> String {
  "~Version\nVERS. 2.0 : version\nWRAP. " +
  wrap +
  " : wrapping\n~Well\nSTRT.M 0 : start\nSTOP.M 2 : stop\nSTEP.M 1 : step\nNULL. -999.25 : null\nWELL. SYNTHETIC : well\n~Curve\nDEPT.M : depth\nGR.GAPI : gamma\n~ASCII\n" +
  data
}

///|
test "LAS header section state machine" {
  let h = read_header(sample_text("NO", "0 10\n1 -999.25\n2 30"))
  assert_eq(h.curves.length(), 2)
  assert_eq(h.data.length(), 3)
  assert_eq(h.null_value, -999.25)
  assert_true(!h.wrapped)
  assert_eq(h.well[4].value, "SYNTHETIC")
}

///|
test "header errors are explicit rather than guessed" {
  for
    text in [
      sample_text("MAYBE", ""),
      sample_text("NO", "").replace(old="2.0", new="3.0"),
      sample_text("NO", "") + "~Curve\n",
    ] {
    let bad = try {
      ignore(read_header(text))
      false
    } catch {
      _ => true
    }
    assert_true(bad)
  }
}
