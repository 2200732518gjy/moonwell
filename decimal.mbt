///|
/// Exact base-ten coefficient/scale. No binary floating-point in standard checks.
priv struct LasDecimal {
  coefficient : @bigint.BigInt
  scale : Int
}

///|
fn decimal_grammar(text : String) -> Bool {
  let chars = text.iter().to_array()
  let mut digits = 0
  let mut dots = 0
  for i in 0..<chars.length() {
    let c = chars[i]
    if c >= '0' && c <= '9' {
      digits += 1
    } else if c == '.' {
      dots += 1
      if dots > 1 {
        return false
      }
    } else if i != 0 || (c != '+' && c != '-') {
      return false
    }
  }
  digits > 0
}

///|
fn exact_decimal(text : String) -> LasDecimal {
  let digits = StringBuilder()
  let mut scale = 0
  let mut fraction = false
  for c in text.iter() {
    if c == '.' {
      fraction = true
    }
    if c >= '0' && c <= '9' {
      digits.write_char(c)
      if fraction {
        scale += 1
      }
    }
  }
  let n = @bigint.BigInt::from_string(digits.to_string())
  { coefficient: if text.has_prefix("-") { -n } else { n }, scale, }
}

///|
fn ten_power(n : Int) -> @bigint.BigInt {
  @bigint.BigInt::from_int(10).pow(@bigint.BigInt::from_int(n))
}

///|
fn decimal_scaled(n : LasDecimal, scale : Int) -> @bigint.BigInt {
  n.coefficient * ten_power(scale - n.scale)
}

///|
fn decimal_compare(a : LasDecimal, b : LasDecimal) -> Int {
  let scale = if a.scale > b.scale { a.scale } else { b.scale }
  decimal_scaled(a, scale).compare(decimal_scaled(b, scale))
}

///|
fn decimal_difference(a : LasDecimal, b : LasDecimal) -> LasDecimal {
  let scale = if a.scale > b.scale { a.scale } else { b.scale }
  { coefficient: decimal_scaled(a, scale) - decimal_scaled(b, scale), scale, }
}

///|
fn decimal_multiple(a : LasDecimal, step : LasDecimal) -> Bool {
  if step.coefficient.is_zero() {
    return true
  }
  let scale = if a.scale > step.scale { a.scale } else { step.scale }
  (decimal_scaled(a, scale) % decimal_scaled(step, scale)).is_zero()
}

///|
fn decimal_string(n : LasDecimal) -> String {
  let text = n.coefficient.to_string()
  let negative = text.has_prefix("-")
  let chars = text.iter().filter(c => c != '-').to_array()
  let out = StringBuilder()
  if negative {
    out.write_char('-')
  }
  let position = chars.length() - n.scale
  if position <= 0 {
    out.write_string("0.")
    for _ in 0..<(0 - position) {
      out.write_char('0')
    }
  }
  for i in 0..<chars.length() {
    if position > 0 && i == position {
      out.write_char('.')
    }
    out.write_char(chars[i])
  }
  out.to_string()
}

///|
/// Expand the shortest round-trippable Double spelling without exponent notation.
/// Does not round to a chosen precision or change observed values.
pub fn las_decimal_text(value : Double) -> String raise WellError {
  if !finite(value) {
    fail("nonfinite LAS value")
  }
  let text = value.to_string().to_upper()
  match text.split_once("E") {
    None => text
    Some((mantissa, exponent)) => {
      let exp = @string.parse_int(exponent.to_owned()) catch {
        _ => {
          fail("invalid numeric exponent from runtime")
          0
        }
      }
      let m = exact_decimal(mantissa.to_owned())
      if exp <= m.scale {
        decimal_string({ coefficient: m.coefficient, scale: m.scale - exp, })
      } else {
        decimal_string({
          coefficient: m.coefficient * ten_power(exp - m.scale),
          scale: 0,
        })
      }
    }
  }
}

///|
fn serialized_step(log : Log) -> String raise WellError {
  if log.rows.length() < 2 {
    return "0"
  }
  let first = exact_decimal(las_decimal_text(log.rows[0][0].unwrap()))
  let second = exact_decimal(las_decimal_text(log.rows[1][0].unwrap()))
  let step = decimal_difference(second, first)
  let mut previous = second
  for i in 2..<log.rows.length() {
    let current = exact_decimal(las_decimal_text(log.rows[i][0].unwrap()))
    if decimal_compare(decimal_difference(current, previous), step) != 0 {
      return "0"
    }
    previous = current
  }
  decimal_string(step)
}
