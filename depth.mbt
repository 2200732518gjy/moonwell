///|
fn rebuild(
  log : Log,
  curves : Array[Curve],
  rows : Array[Array[Double?]],
) -> Log raise WellError {
  make_log(
    curves,
    rows,
    headers=log.headers,
    parameters=log.parameters,
    other=log.other,
    null_value=log.null_value,
  )
}

///|
/// Return an ascending owned copy, never sorting arbitrary invalid depth reversals.
pub fn ascending(log : Log) -> Log raise WellError {
  validate(log)
  let rows : Array[Array[Double?]] = []
  let n = log.rows.length()
  let reverse = n > 1 && log.rows[0][0].unwrap() > log.rows[n - 1][0].unwrap()
  for i in 0..<n {
    rows.push(log.rows[if reverse { n - 1 - i } else { i }])
  }
  rebuild(log, log.curves, rows)
}

///|
/// Inclusive depth window, preserving acquisition order and all curve metadata.
pub fn window(log : Log, low : Double, high : Double) -> Log raise WellError {
  validate(log)
  if !finite(low) || !finite(high) || low > high {
    fail("invalid depth window")
  }
  let rows : Array[Array[Double?]] = []
  for row in log.rows {
    let d = row[0].unwrap()
    if d >= low && d <= high {
      rows.push(row)
    }
  }
  rebuild(log, log.curves, rows)
}

///|
/// Select curves in requested order; depth remains mandatory and first.
pub fn select(log : Log, names : Array[String]) -> Log raise WellError {
  validate(log)
  let indices = [0]
  let curves = [log.curves[0]]
  for name in names {
    let index = curve_index(log, name)
    if index == 0 {
      continue
    }
    if indices.contains(index) {
      fail("duplicate selected curve: " + name)
    }
    indices.push(index)
    curves.push(log.curves[index])
  }
  let rows = log.rows.map(row => indices.map(i => row[i]))
  rebuild(log, curves, rows)
}

///|
/// Construct a finite ascending uniform grid, explicitly bounded before allocation.
pub fn depth_grid(
  start : Double,
  stop : Double,
  step : Double,
  limit? : Int = 100000,
) -> Array[Double] raise WellError {
  if !finite(start) ||
    !finite(stop) ||
    !finite(step) ||
    step <= 0.0 ||
    stop < start {
    fail("grid requires finite ascending endpoints and positive step")
  }
  if limit < 1 || limit > 1000000 {
    fail("grid limit must be 1..1000000")
  }
  let span = stop - start
  if !finite(span) || span / step > (limit - 1).to_double() {
    fail("grid exceeds sample budget")
  }
  let grid : Array[Double] = []
  for i in 0..<limit {
    let d = start + i.to_double() * step
    if d > stop {
      break
    }
    if grid.length() > 0 && d <= grid[grid.length() - 1] {
      fail("grid step below floating point resolution")
    }
    grid.push(d)
  }
  grid
}
