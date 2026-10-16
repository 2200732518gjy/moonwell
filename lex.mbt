///|
fn whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\r' || c == '\n'
}

///|
fn words(text : String) -> Array[String] {
  let out : Array[String] = []
  let buffer = StringBuilder()
  for c in text.iter() {
    if whitespace(c) {
      if !buffer.is_empty() {
        out.push(buffer.to_string())
        buffer.reset()
      }
    } else {
      buffer.write_char(c)
    }
  }
  if !buffer.is_empty() {
    out.push(buffer.to_string())
  }
  out
}

///|
/// Strict decimal numbers with optional E exponent; no NaN/Infinity/hex/underscores.
pub fn parse_number(token : String) -> Double raise WellError {
  if words(token).length() != 1 {
    fail("expected one numeric token")
  }
  let chars = token.iter().to_array()
  let n = chars.length()
  let mut i = 0
  if n > 0 && (chars[0] == '+' || chars[0] == '-') {
    i += 1
  }
  let mut digits = 0
  while i < n && chars[i] >= '0' && chars[i] <= '9' {
    i += 1
    digits += 1
  }
  if i < n && chars[i] == '.' {
    i += 1
    while i < n && chars[i] >= '0' && chars[i] <= '9' {
      i += 1
      digits += 1
    }
  }
  if digits == 0 {
    fail("invalid number: " + token)
  }
  if i < n && (chars[i] == 'e' || chars[i] == 'E') {
    i += 1
    if i < n && (chars[i] == '+' || chars[i] == '-') {
      i += 1
    }
    let start = i
    while i < n && chars[i] >= '0' && chars[i] <= '9' {
      i += 1
    }
    if start == i {
      fail("missing exponent digits: " + token)
    }
  }
  if i != n {
    fail("invalid numeric suffix: " + token)
  }
  let value = @string.parse_double(token) catch {
    _ => {
      fail("number conversion failed")
      0.0
    }
  }
  if !finite(value) {
    fail("number exceeds finite range")
  }
  value
}

///|
/// Parse mnemonic.unit value : description. The last colon separates description (CWLS 2014 section 5.2).
pub fn parse_header(line : String) -> Header raise WellError {
  let (body, description) = match line.rev_split_once(":") {
    Some((a, b)) => (a.to_owned(), b.trim().to_owned())
    None => {
      fail("header requires ':' delimiter")
      ("", "")
    }
  }
  let (left, right) = match body.split_once(".") {
    Some((a, b)) => (a.trim().to_owned(), b.to_owned())
    None => {
      fail("header requires '.' delimiter")
      ("", "")
    }
  }
  if !valid_name(left) {
    fail("invalid header mnemonic: " + left)
  }
  let chars = right.iter().to_array()
  let mut end_unit = 0
  while end_unit < chars.length() && !whitespace(chars[end_unit]) {
    end_unit += 1
  }
  if end_unit == chars.length() {
    fail("header requires space delimiter after unit")
  }
  let unit_buffer = StringBuilder()
  let value_buffer = StringBuilder()
  for i in 0..<end_unit {
    unit_buffer.write_char(chars[i])
  }
  for i in end_unit..<chars.length() {
    value_buffer.write_char(chars[i])
  }
  let unit = unit_buffer.to_string()
  if unit.contains(":") || !safe_text(unit) {
    fail("invalid header unit")
  }
  Header::{
    name: left,
    unit,
    value: value_buffer.to_string().trim().to_owned(),
    description,
  }
}
