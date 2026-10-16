///|
fn header_line(h : Header) -> String {
  h.name + "." + h.unit + " " + h.value + " : " + h.description + "\n"
}

///|
fn cell_text(value : Double?, sentinel : Double) -> String raise WellError {
  match value {
    None => las_decimal_text(sentinel)
    Some(v) => {
      if v == sentinel {
        fail("valid sample collides with NULL sentinel")
      }
      las_decimal_text(v)
    }
  }
}

///|
/// Canonical numerical LAS2 output with opaque curve API codes. Not a full certifier.
pub fn write_las(log : Log, wrapped? : Bool = false) -> String raise WellError {
  validate(log)
  if log.rows.length() == 0 {
    fail("LAS output requires at least one row")
  }
  let first = log.rows[0][0].unwrap()
  let last = log.rows[log.rows.length() - 1][0].unwrap()
  let step = serialized_step(log)
  let mut out = "~Version\nVERS. 2.0 : LAS version\nWRAP. " +
    (if wrapped { "YES" } else { "NO" }) +
    " : wrapping\n"
  for h in log.version_headers {
    out += header_line(h)
  }
  out += "~Well\n"
  for
    pair in [
      ("STRT", las_decimal_text(first)),
      ("STOP", las_decimal_text(last)),
      ("STEP", step),
    ] {
    out += header_line({
      name: pair.0,
      unit: log.curves[0].unit,
      value: pair.1,
      description: "depth grid",
    })
  }
  out += header_line({
    name: "NULL",
    unit: "",
    value: las_decimal_text(log.null_value),
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
    out += c.name +
      "." +
      c.unit +
      " " +
      c.api_code +
      " : " +
      c.description +
      "\n"
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
  for section in log.extra_sections {
    out += section.title + "\n"
    for line in section.lines {
      out += line + "\n"
    }
  }
  out += "~ASCII\n"
  for row in log.rows {
    if wrapped {
      let depth = cell_text(row[0], log.null_value)
      if depth.length() > 78 {
        fail("wrapped index exceeds LAS2 line limit; use unwrapped output")
      }
      out += depth + "\n"
      let mut line = ""
      for i in 1..<row.length() {
        let token = cell_text(row[i], log.null_value)
        if token.length() > 78 {
          fail("wrapped value exceeds LAS2 line limit; use unwrapped output")
        }
        if line != "" && line.length() + 1 + token.length() > 78 {
          out += line + "\n"
          line = ""
        }
        if line != "" {
          line += " "
        }
        line += token
      }
      if line != "" {
        out += line + "\n"
      }
    } else {
      for i in 0..<row.length() {
        if i > 0 {
          out += " "
        }
        out += cell_text(row[i], log.null_value)
      }
      out += "\n"
    }
  }
  out.split("\n").join("\r\n")
}
