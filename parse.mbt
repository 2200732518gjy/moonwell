///|
fn decode_cell(token : String, sentinel : Double) -> Double? raise WellError {
  let value = parse_number(token)
  if value == sentinel {
    None
  } else {
    Some(value)
  }
}

///|
/// Decode LAS2 ASCII. Wrapped records must begin with a depth-only line.
pub fn parse(text : String) -> Log raise WellError {
  let h = read_header(text)
  let rows : Array[Array[Double?]] = []
  let mut pending : Array[Double?] = []
  for line in h.data {
    let tokens = words(line.text)
    if h.wrapped {
      if pending.length() == 0 && h.curves.length() > 1 && tokens.length() != 1 {
        fail(
          "wrapped record must start with depth alone at line " +
          line.number.to_string(),
        )
      }
      if pending.length() + tokens.length() > h.curves.length() {
        fail("wrapped record overflow at line " + line.number.to_string())
      }
      for token in tokens {
        pending.push(decode_cell(token, h.null_value))
      }
      if pending.length() == h.curves.length() {
        rows.push(pending)
        pending = []
      }
    } else {
      if tokens.length() != h.curves.length() {
        fail(
          "ASCII width differs from Curve section at line " +
          line.number.to_string(),
        )
      }
      let row : Array[Double?] = []
      for token in tokens {
        row.push(decode_cell(token, h.null_value))
      }
      rows.push(row)
    }
    if rows.length() > 1000000 {
      fail("row limit is 1000000")
    }
  }
  if pending.length() != 0 {
    fail("incomplete wrapped record at end of input")
  }
  let log = make_log(
    h.curves,
    rows,
    headers=h.well,
    parameters=h.parameters,
    other=h.other,
    null_value=h.null_value,
  )
  if rows.length() > 0 {
    let start = parse_number(header_value(h.well, "STRT").value)
    let stop = parse_number(header_value(h.well, "STOP").value)
    let first = rows[0][0].unwrap()
    let last = rows[rows.length() - 1][0].unwrap()
    let tolerance = 1.0e-8 * (1.0 + first.abs() + last.abs())
    if (start - first).abs() > tolerance || (stop - last).abs() > tolerance {
      fail("STRT/STOP disagree with ASCII depth endpoints")
    }
  }
  log
}
