///|
/// Invalid input, unsupported format or unsafe operation. Messages include context.
pub(all) suberror WellError {
  WellError(String)
}

///|
pub(all) struct Curve {
  name : String
  unit : String
  description : String
}

///|
pub(all) struct Header {
  name : String
  unit : String
  value : String
  description : String
}

///|
/// A rectangular table; column zero is non-null strictly monotonic depth.
/// Arrays are owned snapshots at construction. Call validate after external mutation.
pub struct Log {
  curves : Array[Curve]
  rows : Array[Array[Double?]]
  headers : Array[Header]
  parameters : Array[Header]
  other : Array[String]
  null_value : Double
}

///|
fn fail(message : String) -> Unit raise WellError {
  raise WellError(message)
}

///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn canonical(text : String) -> String {
  text.trim().to_owned().to_upper()
}

///|
fn safe_text(text : String) -> Bool {
  !text.contains("\n") && !text.contains("\r")
}

///|
/// LAS mnemonics are deliberately restricted to ASCII identifiers without delimiters.
fn valid_name(name : String) -> Bool {
  if name.length() == 0 {
    return false
  }
  for c in name.iter() {
    let n = c.to_int()
    if !((n >= 65 && n <= 90) ||
      (n >= 97 && n <= 122) ||
      (n >= 48 && n <= 57) ||
      c == '_' ||
      c == '-') {
      return false
    }
  }
  true
}

///|
pub fn make_log(
  curves : Array[Curve],
  rows : Array[Array[Double?]],
  headers? : Array[Header] = [],
  parameters? : Array[Header] = [],
  other? : Array[String] = [],
  null_value? : Double = -999.25,
) -> Log raise WellError {
  let log = Log::{
    curves: curves.copy(),
    rows: rows.map(row => row.copy()),
    headers: headers.copy(),
    parameters: parameters.copy(),
    other: other.copy(),
    null_value,
  }
  validate(log)
  log
}

///|
pub fn validate(log : Log) -> Unit raise WellError {
  if log.curves.length() == 0 {
    fail("at least one depth curve is required")
  }
  if log.curves.length() > 512 {
    fail("curve limit is 512")
  }
  if log.rows.length() > 1000000 {
    fail("row limit is 1000000")
  }
  if !finite(log.null_value) {
    fail("null sentinel must be finite")
  }
  for i in 0..<log.curves.length() {
    let c = log.curves[i]
    if !valid_name(c.name) {
      fail("invalid curve mnemonic: " + c.name)
    }
    if !safe_text(c.unit) ||
      c.unit.contains(" ") ||
      c.unit.contains("\t") ||
      c.unit.contains(":") ||
      !safe_text(c.description) {
      fail("unsafe curve metadata: " + c.name)
    }
    for j in 0..<i {
      if canonical(c.name) == canonical(log.curves[j].name) {
        fail("duplicate curve: " + c.name)
      }
    }
  }
  let mut direction = 0
  let mut previous = 0.0
  for r in 0..<log.rows.length() {
    let row = log.rows[r]
    if row.length() != log.curves.length() {
      fail("ragged row " + r.to_string())
    }
    let depth = match row[0] {
      Some(v) => v
      None => {
        fail("missing depth at row " + r.to_string())
        0.0
      }
    }
    for value in row {
      if value is Some(v) && !finite(v) {
        fail("nonfinite sample at row " + r.to_string())
      }
    }
    if r > 0 {
      if depth == previous {
        fail("duplicate depth at row " + r.to_string())
      }
      let sign = if depth > previous { 1 } else { -1 }
      if direction != 0 && sign != direction {
        fail("depth reversal at row " + r.to_string())
      }
      direction = sign
    }
    previous = depth
  }
  let all_headers = log.headers.copy()
  for h in log.parameters {
    all_headers.push(h)
  }
  for h in all_headers {
    if !valid_name(h.name) ||
      !safe_text(h.value) ||
      !safe_text(h.unit) ||
      h.unit.contains(" ") ||
      h.unit.contains(":") ||
      !safe_text(h.description) {
      fail("unsafe header: " + h.name)
    }
  }
  for line in log.other {
    if !safe_text(line) || line.trim().has_prefix("~") {
      fail("unsafe Other line")
    }
  }
}

///|
pub fn curve_index(log : Log, name : String) -> Int raise WellError {
  for i in 0..<log.curves.length() {
    if canonical(log.curves[i].name) == canonical(name) {
      return i
    }
  }
  fail("unknown curve: " + name)
  0
}

///|
pub fn depths(log : Log) -> Array[Double] raise WellError {
  validate(log)
  log.rows.map(row => row[0].unwrap())
}
