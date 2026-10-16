///|
/// Median neighborhood in row space, stopping at depth gaps and null samples.
/// Missing centers remain missing; edge neighborhoods are clipped, not padded.
pub fn median_filter(
  log : Log,
  name : String,
  radius : Int,
  max_gap : Double,
) -> Log raise WellError {
  validate(log)
  if radius < 1 || radius > 1000 || !finite(max_gap) || max_gap <= 0.0 {
    fail("invalid filter radius or gap")
  }
  if log.rows.length().to_double() * (2 * radius + 1).to_double() > 20000000.0 {
    fail("filter work budget exceeded")
  }
  let column = curve_index(log, name)
  if column == 0 {
    fail("depth cannot be filtered")
  }
  let rows = log.rows.map(row => row.copy())
  for i in 0..<rows.length() {
    if log.rows[i][column] is None {
      continue
    }
    let values = [log.rows[i][column].unwrap()]
    let mut j = i - 1
    while j >= 0 && i - j <= radius {
      if (log.rows[j + 1][0].unwrap() - log.rows[j][0].unwrap()).abs() > max_gap {
        break
      }
      match log.rows[j][column] {
        Some(v) => values.push(v)
        None => break
      }
      j -= 1
    }
    j = i + 1
    while j < rows.length() && j - i <= radius {
      if (log.rows[j][0].unwrap() - log.rows[j - 1][0].unwrap()).abs() > max_gap {
        break
      }
      match log.rows[j][column] {
        Some(v) => values.push(v)
        None => break
      }
      j += 1
    }
    values.sort()
    rows[i][column] = quantile_sorted(values, 0.5)
  }
  rebuild(log, log.curves, rows)
}

///|
/// Backward adjacent difference / signed depth increment. First row is missing.
/// New curve unit is an explicit ratio; no domain interpretation is attached.
pub fn gradient_curve(
  log : Log,
  name : String,
  output_name : String,
  max_gap : Double,
) -> Log raise WellError {
  validate(log)
  if !finite(max_gap) || max_gap <= 0.0 {
    fail("gradient max_gap must be positive")
  }
  let column = curve_index(log, name)
  if column == 0 {
    fail("gradient requires a non-depth curve")
  }
  let values : Array[Double?] = []
  for i in 0..<log.rows.length() {
    if i == 0 {
      values.push(None)
      continue
    }
    let delta = log.rows[i][0].unwrap() - log.rows[i - 1][0].unwrap()
    if delta.abs() > max_gap {
      values.push(None)
      continue
    }
    match (log.rows[i - 1][column], log.rows[i][column]) {
      (Some(a), Some(b)) => {
        let value = (b - a) / delta
        if !finite(value) {
          fail("gradient overflow")
        }
        values.push(Some(value))
      }
      _ => values.push(None)
    }
  }
  append_curve(
    log,
    {
      name: output_name,
      unit: log.curves[column].unit + "/" + log.curves[0].unit,
      description: "backward adjacent gradient of " + name,
      api_code: "",
    },
    values,
  )
}
