///|
pub struct DataLine {
  number : Int
  text : String
}

///|
pub struct LasHeader {
  curves : Array[Curve]
  well : Array[Header]
  parameters : Array[Header]
  other : Array[String]
  data : Array[DataLine]
  wrapped : Bool
  null_value : Double
}

///|
fn header_value(
  headers : Array[Header],
  name : String,
) -> Header raise WellError {
  for h in headers {
    if canonical(h.name) == name {
      return h
    }
  }
  fail("missing required header: " + name)
  Header::{ name, unit: "", value: "", description: "", }
}

///|
fn insert_header(headers : Array[Header], h : Header) -> Unit raise WellError {
  for old in headers {
    if canonical(old.name) == canonical(h.name) {
      fail("duplicate header: " + h.name)
    }
  }
  headers.push(h)
}

///|
/// Parse the bounded section state machine. No data is decoded at this stage.
pub fn read_header(text : String) -> LasHeader raise WellError {
  if text.length() > 16000000 {
    fail("input exceeds 16000000 code units")
  }
  let version : Array[Header] = []
  let well : Array[Header] = []
  let parameters : Array[Header] = []
  let curves : Array[Curve] = []
  let other : Array[String] = []
  let data : Array[DataLine] = []
  let seen : Array[String] = []
  let mut section = ""
  let mut number = 0
  for raw in text.split("\n") {
    number += 1
    let line = raw.trim().to_owned()
    if line == "" {
      continue
    }
    if line.has_prefix("~") {
      let tag = canonical(line)
      let next = if tag.has_prefix("~V") {
        "V"
      } else if tag.has_prefix("~W") {
        "W"
      } else if tag.has_prefix("~C") {
        "C"
      } else if tag.has_prefix("~P") {
        "P"
      } else if tag.has_prefix("~O") {
        "O"
      } else if tag.has_prefix("~A") {
        "A"
      } else {
        fail("unsupported section at line " + number.to_string())
        ""
      }
      if section == "A" {
        fail("sections after ASCII are unsupported")
      }
      if seen.contains(next) {
        fail("duplicate section: " + next)
      }
      if next == "A" &&
        (!seen.contains("V") || !seen.contains("W") || !seen.contains("C")) {
        fail("Version, Well and Curve sections must precede ASCII")
      }
      seen.push(next)
      section = next
      continue
    }
    if line.has_prefix("#") {
      continue
    }
    if section == "A" {
      data.push({ number, text: line, })
      continue
    }
    if section == "O" {
      other.push(line)
      continue
    }
    if section == "" {
      fail("content before section at line " + number.to_string())
    }
    let h = parse_header(line) catch {
      WellError(message) => {
        fail("line " + number.to_string() + ": " + message)
        Header::{ name: "", unit: "", value: "", description: "", }
      }
    }
    match section {
      "V" => insert_header(version, h)
      "W" => insert_header(well, h)
      "P" => insert_header(parameters, h)
      "C" => {
        if h.value != "" {
          fail("curve line may not contain a value")
        }
        curves.push({ name: h.name, unit: h.unit, description: h.description, })
        if curves.length() > 512 {
          fail("curve limit is 512")
        }
      }
      _ => fail("invalid parser state")
    }
  }
  if !seen.contains("A") {
    fail("missing ASCII section")
  }
  if parse_number(header_value(version, "VERS").value) != 2.0 {
    fail("only LAS 2.0 is supported")
  }
  let wrap = canonical(header_value(version, "WRAP").value)
  if wrap != "YES" && wrap != "NO" {
    fail("WRAP must be YES or NO")
  }
  if curves.length() == 0 {
    fail("Curve section is empty")
  }
  for name in ["STRT", "STOP", "STEP"] {
    let h = header_value(well, name)
    ignore(parse_number(h.value))
    if canonical(h.unit) != canonical(curves[0].unit) {
      fail(name + " unit differs from depth curve")
    }
  }
  let null_value = parse_number(header_value(well, "NULL").value)
  LasHeader::{
    curves,
    well,
    parameters,
    other,
    data,
    wrapped: wrap == "YES",
    null_value,
  }
}
