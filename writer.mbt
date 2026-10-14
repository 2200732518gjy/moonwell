///|
fn header_line(h : Header) -> String {
  h.name + "." + h.unit + " " + h.value + " : " + h.description + "\n"
}

///|
fn cell_text(value : Double?, sentinel : Double) -> String raise WellError {
  match value {
    None => sentinel.to_string()
    Some(v) => {
      if v == sentinel {
        fail("valid sample collides with NULL sentinel")
      }
      v.to_string()
    }
  }
}

///|
/// Canonical LAS2 subset, recomputing depth headers. Empty logs cannot be serialized.
pub fn write_las(log : Log, wrapped? : Bool = false) -> String raise WellError {
  validate(log)
  if log.rows.length() == 0 {
    fail("LAS output requires at least one row")
  }
  let first = log.rows[0][0].unwrap()
  let last = log.rows[log.rows.length() - 1][0].unwrap()
  let mut step = 0.0
  if log.rows.length() > 1 {
    step = log.rows[1][0].unwrap() - first
    for i in 2..<log.rows.length() {
      let delta = log.rows[i][0].unwrap() - log.rows[i - 1][0].unwrap()
      if (delta - step).abs() > 1.0e-9 * (1.0 + step.abs()) {
        step = 0.0
        break
      }
    }
  }
  let mut out = "~Version\nVERS. 2.0 : LAS version\nWRAP. " +
    (if wrapped { "YES" } else { "NO" }) +
    " : wrapping\n~Well\n"
  for pair in [("STRT", first), ("STOP", last), ("STEP", step)] {
    out += header_line({
      name: pair.0,
      unit: log.curves[0].unit,
      value: pair.1.to_string(),
      description: "depth grid",
    })
  }
  out += header_line({
    name: "NULL",
    unit: "",
    value: log.null_value.to_string(),
    description: "missing value",
  })
  for h in log.headers {
    let key = canonical(h.name)
    if key != "STRT" && key != "STOP" && key != "STEP" && key != "NULL" {
      out += header_line(h)
    }
  }
  out += "~Curve\n"
  for c in log.curves {
    out += c.name + "." + c.unit + " : " + c.description + "\n"
  }
  if log.parameters.length() > 0 {
    out += "~Parameter\n"
    for h in log.parameters {
      out += header_line(h)
    }
  }
  if log.other.length() > 0 {
    out += "~Other\n"
    for line in log.other {
      out += line + "\n"
    }
  }
  out += "~ASCII\n"
  for row in log.rows {
    for i in 0..<row.length() {
      if i > 0 {
        out += if wrapped && i == 1 { "\n" } else { " " }
      }
      out += cell_text(row[i], log.null_value)
    }
    out += "\n"
  }
  out
}
