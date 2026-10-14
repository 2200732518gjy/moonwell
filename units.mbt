///|
fn unit_definition(unit : String) -> (String, Double, Double)? {
  match canonical(unit) {
    "M" | "METRE" | "METER" => Some(("length", 1.0, 0.0))
    "FT" | "FEET" => Some(("length", 0.3048, 0.0))
    "CM" => Some(("length", 0.01, 0.0))
    "MM" => Some(("length", 0.001, 0.0))
    "IN" => Some(("length", 0.0254, 0.0))
    "V" => Some(("voltage", 1.0, 0.0))
    "MV" => Some(("voltage", 0.001, 0.0))
    "G/CC" | "G/CM3" => Some(("density", 1000.0, 0.0))
    "KG/M3" => Some(("density", 1.0, 0.0))
    "DEGC" => Some(("temperature", 1.0, 273.15))
    "DEGF" => Some(("temperature", 5.0 / 9.0, 255.3722222222222))
    "K" => Some(("temperature", 1.0, 0.0))
    "US/FT" => Some(("slowness", 1.0 / 0.3048, 0.0))
    "US/M" => Some(("slowness", 1.0, 0.0))
    _ => None
  }
}

///|
/// Unknown units may pass through identically, but are never guessed or relabelled.
pub fn convert_value(
  value : Double,
  from : String,
  to : String,
) -> Double raise WellError {
  if !finite(value) {
    fail("unit conversion requires finite input")
  }
  if canonical(from) == canonical(to) {
    return value
  }
  let result = match (unit_definition(from), unit_definition(to)) {
    (Some(a), Some(b)) => {
      if a.0 != b.0 {
        fail("incompatible unit dimensions: " + from + " -> " + to)
      }
      (value * a.1 + a.2 - b.2) / b.1
    }
    _ => {
      fail("unknown unit conversion: " + from + " -> " + to)
      0.0
    }
  }
  if !finite(result) {
    fail("unit conversion overflow")
  }
  result
}

///|
pub fn convert_curve(
  log : Log,
  name : String,
  unit : String,
) -> Log raise WellError {
  validate(log)
  let column = curve_index(log, name)
  let old = log.curves[column]
  ignore(convert_value(0.0, old.unit, unit))
  let curves = log.curves.copy()
  curves[column] = { name: old.name, unit, description: old.description, }
  let rows : Array[Array[Double?]] = []
  for original in log.rows {
    let row = original.copy()
    if row[column] is Some(value) {
      row[column] = Some(convert_value(value, old.unit, unit))
    }
    rows.push(row)
  }
  let headers : Array[Header] = []
  for h in log.headers {
    let key = canonical(h.name)
    if column == 0 && (key == "STRT" || key == "STOP" || key == "STEP") {
      headers.push({
        name: h.name,
        unit,
        value: convert_value(parse_number(h.value), old.unit, unit).to_string(),
        description: h.description,
      })
    } else {
      headers.push(h)
    }
  }
  make_log(
    curves,
    rows,
    headers~,
    parameters=log.parameters,
    other=log.other,
    null_value=log.null_value,
  )
}
