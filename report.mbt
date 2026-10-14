///|
fn json_number(value : Double?) -> Json {
  match value {
    Some(v) => Json::number(v)
    None => Json::null()
  }
}

///|
fn summary_json(s : Summary) -> Json {
  Json::object({
    "present": Json::number(s.present.to_double()),
    "missing": Json::number(s.missing.to_double()),
    "coverage": Json::number(s.coverage),
    "min": json_number(s.minimum),
    "max": json_number(s.maximum),
    "mean": json_number(s.mean),
    "population_variance": json_number(s.variance),
    "median": json_number(s.median),
  })
}

///|
/// Versioned machine report. Statistics remain distinct from rule-based QC findings.
pub fn quality_report(
  log : Log,
  rules : Array[QcRule],
  max_depth_gap : Double,
) -> Json raise WellError {
  let issues = quality_check(log, rules, max_depth_gap)
  let curves : Array[Json] = []
  for c in log.curves {
    let spans = missing_spans(log, c.name)
    curves.push(
      Json::object({
        "name": Json::string(c.name),
        "unit": Json::string(c.unit),
        "summary": summary_json(summarize(log, c.name)),
        "missing_spans": Json::array(
          spans.map(s => {
            Json::object({
              "first_row": Json::number(s.first_row.to_double()),
              "last_row": Json::number(s.last_row.to_double()),
              "start_depth": Json::number(s.start_depth),
              "stop_depth": Json::number(s.stop_depth),
              "bounded": Json::boolean(s.bounded),
            })
          }),
        ),
      }),
    )
  }
  Json::object({
    "schema": Json::string("moonwell.qa/v1"),
    "rows": Json::number(log.rows.length().to_double()),
    "curves": Json::array(curves),
    "issues": Json::array(
      issues.map(i => {
        Json::object({
          "code": Json::string(i.code),
          "curve": Json::string(i.curve),
          "row": Json::number(i.row.to_double()),
          "depth": Json::number(i.depth),
          "message": Json::string(i.message),
        })
      }),
    ),
  })
}

///|
/// Contains complete per-cell sources, including explicit null and synthetic depth cells.
pub fn assembly_report(assembly : Assembly) -> Json raise WellError {
  validate_assembly(assembly)
  let sources : Array[Json] = []
  for row in assembly.sources {
    sources.push(
      Json::array(
        row.map(cell => {
          match cell {
            None => Json::null()
            Some(s) =>
              Json::object({
                "run": Json::number(s.run.to_double()),
                "interpolated": Json::boolean(s.interpolated),
              })
          }
        }),
      ),
    )
  }
  let conflicts = assembly.conflicts.map(c => {
    Json::object({
      "row": Json::number(c.row.to_double()),
      "depth": Json::number(c.depth),
      "curve": Json::string(c.curve),
      "previous_run": Json::number(c.kept_run.to_double()),
      "incoming_run": Json::number(c.incoming_run.to_double()),
      "previous_value": Json::number(c.kept_value),
      "incoming_value": Json::number(c.incoming_value),
    })
  })
  Json::object({
    "schema": Json::string("moonwell.assembly/v1"),
    "runs": Json::array(assembly.run_names.map(Json::string)),
    "curves": Json::array(assembly.log.curves.map(c => Json::string(c.name))),
    "depths": Json::array(depths(assembly.log).map(d => Json::number(d))),
    "sources": Json::array(sources),
    "conflicts": Json::array(conflicts),
  })
}

///|
pub fn interval_report(summary : IntervalSummary) -> Json {
  Json::object({
    "schema": Json::string("moonwell.interval/v1"),
    "start": Json::number(summary.start),
    "stop": Json::number(summary.stop),
    "covered": Json::number(summary.covered),
    "coverage": Json::number(summary.coverage),
    "integral": Json::number(summary.integral),
    "weighted_mean": json_number(summary.weighted_mean),
    "segments": Json::number(summary.segments.to_double()),
  })
}

///|
pub fn report_text(report : Json) -> String {
  report.stringify(indent=2)
}

///|
/// Bounded report decoder for downstream integrations.
pub fn read_report(text : String) -> Json raise WellError {
  if text.length() > 16000000 {
    fail("report size limit exceeded")
  }
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  for c in text.iter() {
    if quoted {
      if escaped {
        escaped = false
      } else if c == '\\' {
        escaped = true
      } else if c == '"' {
        quoted = false
      }
    } else if c == '"' {
      quoted = true
    } else if c == '[' || c == '{' {
      depth += 1
      if depth > 32 {
        fail("report nesting limit is 32")
      }
    } else if c == ']' || c == '}' {
      depth -= 1
    }
  }
  @json.parse(text) catch {
    _ => {
      fail("invalid report JSON")
      Json::null()
    }
  }
}
