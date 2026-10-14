///|
pub struct Summary {
  present : Int
  missing : Int
  coverage : Double
  minimum : Double?
  maximum : Double?
  mean : Double?
  variance : Double?
  median : Double?
}

///|
fn curve_values(log : Log, column : Int) -> Array[Double] {
  let values : Array[Double] = []
  for row in log.rows {
    if row[column] is Some(v) {
      values.push(v)
    }
  }
  values
}

///|
fn quantile_sorted(values : Array[Double], probability : Double) -> Double? {
  if values.length() == 0 {
    return None
  }
  let position = probability * (values.length() - 1).to_double()
  let left = position.to_int()
  let right = if left + 1 < values.length() { left + 1 } else { left }
  let weight = position - left.to_double()
  Some((1.0 - weight) * values[left] + weight * values[right])
}

///|
/// Type-7 linear quantile, ignoring missing samples; rejects invalid probabilities.
pub fn quantile(
  log : Log,
  name : String,
  probability : Double,
) -> Double? raise WellError {
  validate(log)
  if !finite(probability) || probability < 0.0 || probability > 1.0 {
    fail("probability must be in [0,1]")
  }
  let values = curve_values(log, curve_index(log, name))
  values.sort()
  quantile_sorted(values, probability)
}

///|
/// Population variance (not sample variance), with scaled Welford accumulation.
pub fn summarize(log : Log, name : String) -> Summary raise WellError {
  validate(log)
  let values = curve_values(log, curve_index(log, name))
  values.sort()
  let n = values.length()
  let total = log.rows.length()
  let coverage = if total == 0 {
    0.0
  } else {
    n.to_double() / total.to_double()
  }
  if n == 0 {
    return {
      present: 0,
      missing: total,
      coverage,
      minimum: None,
      maximum: None,
      mean: None,
      variance: None,
      median: None,
    }
  }
  let mut scale = 0.0
  for v in values {
    if v.abs() > scale {
      scale = v.abs()
    }
  }
  let mut mean = 0.0
  let mut m2 = 0.0
  if scale > 0.0 {
    for i in 0..<n {
      let x = values[i] / scale
      let delta = x - mean
      mean += delta / (i + 1).to_double()
      m2 += delta * (x - mean)
    }
  }
  let variance = m2 / n.to_double() * scale * scale
  if !finite(variance) {
    fail("variance exceeds finite output range")
  }
  Summary::{
    present: n,
    missing: total - n,
    coverage,
    minimum: Some(values[0]),
    maximum: Some(values[n - 1]),
    mean: Some(mean * scale),
    variance: Some(variance),
    median: quantile_sorted(values, 0.5),
  }
}
