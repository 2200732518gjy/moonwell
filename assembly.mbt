///|
pub(all) enum ConflictPolicy {
  Reject
  PreferFirst
  PreferLast
}

///|
pub struct CellSource {
  run : Int
  interpolated : Bool
}

///|
pub struct Conflict {
  row : Int
  curve : String
  depth : Double
  kept_run : Int
  incoming_run : Int
  kept_value : Double
  incoming_value : Double
}

///|
pub struct Assembly {
  log : Log
  sources : Array[Array[CellSource?]]
  conflicts : Array[Conflict]
  run_names : Array[String]
}

///|
fn exact_depth(log : Log, depth : Double) -> Bool {
  let mut lo = 0
  let mut hi = log.rows.length()
  while lo < hi {
    let mid = lo + (hi - lo) / 2
    if log.rows[mid][0].unwrap() < depth {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  lo < log.rows.length() && log.rows[lo][0].unwrap() == depth
}

///|
/// Assemble named runs on an explicit common grid. The first run sets target units.
/// Case-insensitive curve identity, no alias guessing, source retained per non-null cell.
pub fn assemble(
  runs : Array[Log],
  names : Array[String],
  grid : Array[Double],
  max_gap : Double,
  policy : ConflictPolicy,
  tolerance? : Double = 0.0,
) -> Assembly raise WellError {
  if runs.length() == 0 || runs.length() > 64 || names.length() != runs.length() {
    fail("assembly needs 1..64 uniquely named runs")
  }
  if !finite(tolerance) || tolerance < 0.0 {
    fail("conflict tolerance must be finite and nonnegative")
  }
  for i in 0..<names.length() {
    if names[i].trim().is_empty() || !safe_text(names[i]) {
      fail("unsafe run name")
    }
    for j in 0..<i {
      if names[i] == names[j] {
        fail("duplicate run name")
      }
    }
    validate(runs[i])
  }
  let curves = runs[0].curves.copy()
  for log in runs {
    for c in 1..<log.curves.length() {
      let incoming = log.curves[c]
      let mut found = false
      for target in curves {
        if canonical(target.name) == canonical(incoming.name) {
          found = true
          break
        }
      }
      if !found {
        curves.push(incoming)
      }
    }
  }
  if curves.length() > 512 ||
    grid.length().to_double() *
    curves.length().to_double() *
    runs.length().to_double() >
    20000000.0 {
    fail("assembly cell-work budget exceeded")
  }
  // Validate the grid and max_gap even for runs with no non-depth curves.
  ignore(resample(select(runs[0], []), grid, max_gap))
  let rows : Array[Array[Double?]] = []
  let sources : Array[Array[CellSource?]] = []
  for depth in grid {
    let row : Array[Double?] = [Some(depth)]
    let provenance : Array[CellSource?] = [None]
    for _ in 1..<curves.length() {
      row.push(None)
      provenance.push(None)
    }
    rows.push(row)
    sources.push(provenance)
  }
  let conflicts : Array[Conflict] = []
  for run in 0..<runs.length() {
    let mut normalized = convert_curve(
      runs[run],
      runs[run].curves[0].name,
      curves[0].unit,
    )
    for c in 1..<normalized.curves.length() {
      let incoming = normalized.curves[c]
      for target in curves {
        if canonical(target.name) == canonical(incoming.name) {
          normalized = convert_curve(normalized, incoming.name, target.unit)
          break
        }
      }
    }
    let sorted = ascending(normalized)
    for c in 1..<sorted.curves.length() {
      let mut output = 0
      for j in 1..<curves.length() {
        if canonical(curves[j].name) == canonical(sorted.curves[c].name) {
          output = j
          break
        }
      }
      if output == 0 {
        fail("non-depth curve collides with depth mnemonic")
      }
      for i in 0..<grid.length() {
        let incoming = sample_sorted(sorted, c, grid[i], max_gap)
        if incoming is Some(value) {
          let provenance = CellSource::{
            run,
            interpolated: !exact_depth(sorted, grid[i]),
          }
          match rows[i][output] {
            None => {
              rows[i][output] = incoming
              sources[i][output] = Some(provenance)
            }
            Some(old) =>
              if (old - value).abs() > tolerance {
                let kept = sources[i][output].unwrap().run
                conflicts.push({
                  row: i,
                  curve: curves[output].name,
                  depth: grid[i],
                  kept_run: kept,
                  incoming_run: run,
                  kept_value: old,
                  incoming_value: value,
                })
                match policy {
                  Reject =>
                    fail(
                      "conflicting run samples at depth " +
                      grid[i].to_string() +
                      " curve " +
                      curves[output].name,
                    )
                  PreferFirst => ()
                  PreferLast => {
                    rows[i][output] = incoming
                    sources[i][output] = Some(provenance)
                  }
                }
              }
          }
        }
      }
    }
  }
  let log = rebuild(runs[0], curves, rows)
  Assembly::{ log, sources, conflicts, run_names: names.copy(), }
}
