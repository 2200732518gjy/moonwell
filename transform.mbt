///|
/// Rename metadata without permitting ambiguity or changing numerical values.
pub fn rename_curve(
  log : Log,
  name : String,
  replacement : String,
) -> Log raise WellError {
  validate(log)
  let column = curve_index(log, name)
  let old = log.curves[column]
  let curves = log.curves.copy()
  curves[column] = {
    name: replacement,
    unit: old.unit,
    description: old.description,
  }
  rebuild(log, curves, log.rows)
}

///|
/// Affine value transform; depth uses dedicated dimensional conversion instead.
pub fn affine_curve(
  log : Log,
  name : String,
  scale : Double,
  offset : Double,
) -> Log raise WellError {
  validate(log)
  if !finite(scale) || !finite(offset) {
    fail("affine coefficients must be finite")
  }
  let column = curve_index(log, name)
  if column == 0 {
    fail("use convert_curve for depth conversion")
  }
  let rows = log.rows.map(row => row.copy())
  for row in rows {
    if row[column] is Some(value) {
      let result = value * scale + offset
      if !finite(result) {
        fail("affine overflow")
      }
      row[column] = Some(result)
    }
  }
  rebuild(log, log.curves, rows)
}

///|
/// Null samples outside inclusive bounds rather than silently clamping outliers.
pub fn mask_range(
  log : Log,
  name : String,
  minimum : Double,
  maximum : Double,
) -> Log raise WellError {
  validate(log)
  if !finite(minimum) || !finite(maximum) || minimum > maximum {
    fail("invalid masking range")
  }
  let column = curve_index(log, name)
  if column == 0 {
    fail("depth cannot be masked")
  }
  let rows = log.rows.map(row => row.copy())
  for row in rows {
    if row[column] is Some(value) && (value < minimum || value > maximum) {
      row[column] = None
    }
  }
  rebuild(log, log.curves, rows)
}

///|
/// Add an explicitly described derived column, validating all input and output.
pub fn append_curve(
  log : Log,
  curve : Curve,
  values : Array[Double?],
) -> Log raise WellError {
  validate(log)
  if values.length() != log.rows.length() {
    fail("derived curve row count mismatch")
  }
  let curves = log.curves.copy()
  curves.push(curve)
  let rows = log.rows.map(row => row.copy())
  for i in 0..<rows.length() {
    rows[i].push(values[i])
  }
  rebuild(log, curves, rows)
}
