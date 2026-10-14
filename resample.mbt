///|
fn sample_sorted(
  log : Log,
  column : Int,
  depth : Double,
  max_gap : Double,
) -> Double? {
  let n = log.rows.length()
  if n == 0 {
    return None
  }
  let mut lo = 0
  let mut hi = n
  while lo < hi {
    let mid = lo + (hi - lo) / 2
    if log.rows[mid][0].unwrap() < depth {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  if lo < n && log.rows[lo][0].unwrap() == depth {
    return log.rows[lo][column]
  }
  if lo == 0 || lo == n {
    return None
  }
  let a = log.rows[lo - 1]
  let b = log.rows[lo]
  let gap = b[0].unwrap() - a[0].unwrap()
  if gap > max_gap {
    return None
  }
  match (a[column], b[column]) {
    (Some(x), Some(y)) => {
      let weight = (depth - a[0].unwrap()) / gap
      let value = (1.0 - weight) * x + weight * y
      if finite(value) {
        Some(value)
      } else {
        None
      }
    }
    _ => None
  }
}

///|
/// Interpolate only between adjacent valid endpoints within max_gap, never extrapolate.
pub fn sample(
  log : Log,
  name : String,
  depth : Double,
  max_gap : Double,
) -> Double? raise WellError {
  if !finite(depth) || !finite(max_gap) || max_gap <= 0.0 {
    fail("sample requires finite depth and positive max_gap")
  }
  let sorted = ascending(log)
  let column = curve_index(sorted, name)
  sample_sorted(sorted, column, depth, max_gap)
}

///|
/// Output grid must be finite, unique and ascending; preserves explicit null spans.
pub fn resample(
  log : Log,
  grid : Array[Double],
  max_gap : Double,
) -> Log raise WellError {
  if !finite(max_gap) || max_gap <= 0.0 {
    fail("max_gap must be finite and positive")
  }
  if grid.length() > 1000000 {
    fail("resample row budget exceeded")
  }
  let sorted = ascending(log)
  if grid.length().to_double() * sorted.curves.length().to_double() > 10000000.0 {
    fail("resample cell budget is 10000000")
  }
  let rows : Array[Array[Double?]] = []
  for i in 0..<grid.length() {
    let depth = grid[i]
    if !finite(depth) || (i > 0 && depth <= grid[i - 1]) {
      fail("invalid output grid")
    }
    let row : Array[Double?] = [Some(depth)]
    for column in 1..<sorted.curves.length() {
      row.push(sample_sorted(sorted, column, depth, max_gap))
    }
    rows.push(row)
  }
  rebuild(sorted, sorted.curves, rows)
}
