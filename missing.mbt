///|
pub struct MissingSpan {
  first_row : Int
  last_row : Int
  start_depth : Double
  stop_depth : Double
  count : Int
  bounded : Bool
}

///|
/// Contiguous missing samples in acquisition order, including leading/trailing spans.
pub fn missing_spans(
  log : Log,
  name : String,
) -> Array[MissingSpan] raise WellError {
  validate(log)
  let c = curve_index(log, name)
  let spans : Array[MissingSpan] = []
  let mut i = 0
  while i < log.rows.length() {
    if log.rows[i][c] is Some(_) {
      i += 1
      continue
    }
    let first = i
    while i < log.rows.length() && log.rows[i][c] is None {
      i += 1
    }
    let last = i - 1
    spans.push({
      first_row: first,
      last_row: last,
      start_depth: log.rows[first][0].unwrap(),
      stop_depth: log.rows[last][0].unwrap(),
      count: i - first,
      bounded: first > 0 && i < log.rows.length(),
    })
  }
  spans
}

///|
/// Fill only bounded null runs whose supporting endpoint distance is within max_gap.
/// Does not interpolate already-present values, extend edges, or bridge large gaps.
pub fn fill_linear(
  log : Log,
  name : String,
  max_gap : Double,
) -> Log raise WellError {
  validate(log)
  if !finite(max_gap) || max_gap <= 0.0 {
    fail("fill max_gap must be finite and positive")
  }
  let column = curve_index(log, name)
  if column == 0 {
    fail("depth cannot be filled")
  }
  let rows = log.rows.map(row => row.copy())
  for span in missing_spans(log, name) {
    if !span.bounded {
      continue
    }
    let left = span.first_row - 1
    let right = span.last_row + 1
    let a = rows[left][0].unwrap()
    let b = rows[right][0].unwrap()
    if (b - a).abs() > max_gap {
      continue
    }
    let x = rows[left][column].unwrap()
    let y = rows[right][column].unwrap()
    for i in span.first_row..<right {
      let weight = (rows[i][0].unwrap() - a) / (b - a)
      let value = (1.0 - weight) * x + weight * y
      if !finite(value) {
        fail("fill overflow")
      }
      rows[i][column] = Some(value)
    }
  }
  rebuild(log, log.curves, rows)
}

///|
/// Explicit constant fill, never applying to the depth index.
pub fn fill_constant(
  log : Log,
  name : String,
  value : Double,
) -> Log raise WellError {
  validate(log)
  if !finite(value) {
    fail("fill value must be finite")
  }
  let column = curve_index(log, name)
  if column == 0 {
    fail("depth cannot be filled")
  }
  let rows = log.rows.map(row => row.copy())
  for row in rows {
    if row[column] is None {
      row[column] = Some(value)
    }
  }
  rebuild(log, log.curves, rows)
}
