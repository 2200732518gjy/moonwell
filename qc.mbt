///|
pub struct Issue {
  code : String
  curve : String
  row : Int
  depth : Double
  message : String
}

///|
pub(all) struct QcRule {
  curve : String
  minimum : Double?
  maximum : Double?
  max_gradient : Double?
  constant_run : Int
}

///|
/// Rules run in caller order, rows in acquisition order. No interpretations inferred.
pub fn quality_check(
  log : Log,
  rules : Array[QcRule],
  max_depth_gap : Double,
) -> Array[Issue] raise WellError {
  validate(log)
  if !finite(max_depth_gap) || max_depth_gap <= 0.0 {
    fail("QC depth gap must be positive and finite")
  }
  if rules.length() > 512 {
    fail("QC rule budget is 512")
  }
  let issues : Array[Issue] = []
  for i in 1..<log.rows.length() {
    let delta = (log.rows[i][0].unwrap() - log.rows[i - 1][0].unwrap()).abs()
    if delta > max_depth_gap {
      issues.push({
        code: "DEPTH_GAP",
        curve: log.curves[0].name,
        row: i,
        depth: log.rows[i][0].unwrap(),
        message: "depth gap " + delta.to_string(),
      })
    }
  }
  for rule in rules {
    let c = curve_index(log, rule.curve)
    for v in [rule.minimum, rule.maximum, rule.max_gradient] {
      if v is Some(x) && !finite(x) {
        fail("QC thresholds must be finite")
      }
    }
    if rule.minimum is Some(lo) && rule.maximum is Some(hi) && lo > hi {
      fail("QC bounds reversed")
    }
    if rule.max_gradient is Some(g) && g < 0.0 {
      fail("QC gradient must be nonnegative")
    }
    if rule.constant_run < 0 || rule.constant_run == 1 {
      fail("constant run is disabled (0) or at least 2")
    }
    let mut run = 0
    let mut previous : Double? = None
    for i in 0..<log.rows.length() {
      let depth = log.rows[i][0].unwrap()
      let value = log.rows[i][c]
      let codes : Array[String] = []
      match value {
        None => {
          codes.push("MISSING")
          run = 0
        }
        Some(v) => {
          if rule.minimum is Some(lo) && v < lo {
            codes.push("BELOW_MIN")
          }
          if rule.maximum is Some(hi) && v > hi {
            codes.push("ABOVE_MAX")
          }
          if previous is Some(p) {
            run = if p == v { run + 1 } else { 1 }
            if rule.max_gradient is Some(g) && i > 0 {
              let gradient = adjacent_gradient(
                p,
                v,
                log.rows[i - 1][0].unwrap(),
                depth,
              )
              if gradient.abs() > g {
                codes.push("GRADIENT")
              }
            }
          } else {
            run = 1
          }
          if rule.constant_run > 0 && run == rule.constant_run {
            codes.push("CONSTANT_RUN")
          }
        }
      }
      for code in codes {
        issues.push({
          code,
          curve: log.curves[c].name,
          row: i,
          depth,
          message: "rule violation",
        })
        if issues.length() > 1000000 {
          fail("QC issue budget exceeded")
        }
      }
      previous = value
    }
  }
  issues
}
