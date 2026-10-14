///|
pub struct IntervalSummary {
  start : Double
  stop : Double
  covered : Double
  coverage : Double
  integral : Double
  weighted_mean : Double?
  segments : Int
}

///|
/// Integrate clipped adjacent segments with valid endpoints, no bridging nulls/gaps.
pub fn summarize_interval(
  log : Log,
  name : String,
  start : Double,
  stop : Double,
  max_gap : Double,
) -> IntervalSummary raise WellError {
  if !finite(start) || !finite(stop) || start >= stop || !finite(stop - start) {
    fail("interval requires finite start < stop")
  }
  if !finite(max_gap) || max_gap <= 0.0 {
    fail("interval max_gap must be positive")
  }
  let sorted = ascending(log)
  let c = curve_index(sorted, name)
  let mut covered = 0.0
  let mut integral = 0.0
  let mut correction = 0.0
  let mut segments = 0
  for i in 1..<sorted.rows.length() {
    let a = sorted.rows[i - 1]
    let b = sorted.rows[i]
    let da = a[0].unwrap()
    let db = b[0].unwrap()
    let gap = db - da
    if gap > max_gap || db <= start || da >= stop {
      continue
    }
    match (a[c], b[c]) {
      (Some(x), Some(y)) => {
        let left = if da < start { start } else { da }
        let right = if db > stop { stop } else { db }
        let wl = (left - da) / gap
        let wr = (right - da) / gap
        let vl = (1.0 - wl) * x + wl * y
        let vr = (1.0 - wr) * x + wr * y
        let area = (0.5 * vl + 0.5 * vr) * (right - left)
        if !finite(area) {
          fail("interval integral overflow")
        }
        let adjusted = area - correction
        let next = integral + adjusted
        correction = next - integral - adjusted
        integral = next
        covered += right - left
        segments += 1
      }
      _ => ()
    }
  }
  if !finite(integral) {
    fail("interval total overflow")
  }
  let weighted_mean = if covered == 0.0 {
    None
  } else {
    Some(integral / covered)
  }
  IntervalSummary::{
    start,
    stop,
    covered,
    coverage: covered / (stop - start),
    integral,
    weighted_mean,
    segments,
  }
}
