///|
fn csv_field(text : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for c in text.iter() {
    if c == '"' {
      out.write_char('"')
    }
    out.write_char(c)
  }
  out.write_char('"')
  out.to_string()
}

///|
/// CSV with quoted mnemonic/unit header, CRLF records and empty missing cells.
/// Intended for numerical pipelines, not spreadsheet formulas or LAS roundtrips.
pub fn write_csv(
  log : Log,
  include_units? : Bool = true,
) -> String raise WellError {
  validate(log)
  let out = StringBuilder()
  for i in 0..<log.curves.length() {
    if i > 0 {
      out.write_string(",")
    }
    let c = log.curves[i]
    out.write_string(
      csv_field(c.name + (if include_units { " [" + c.unit + "]" } else { "" })),
    )
  }
  out.write_string("\r\n")
  for row in log.rows {
    for i in 0..<row.length() {
      if i > 0 {
        out.write_string(",")
      }
      if row[i] is Some(value) {
        out.write_string(value.to_string())
      }
    }
    out.write_string("\r\n")
  }
  out.to_string()
}

///|
/// Long-form provenance CSV; null cells omitted and synthetic depth has no run owner.
pub fn provenance_csv(assembly : Assembly) -> String raise WellError {
  validate_assembly(assembly)
  let out = StringBuilder()
  out.write_string("depth,curve,run,interpolated,value\r\n")
  for i in 0..<assembly.log.rows.length() {
    for c in 1..<assembly.log.curves.length() {
      if assembly.sources[i][c] is Some(source) {
        out.write_string(assembly.log.rows[i][0].unwrap().to_string() + ",")
        out.write_string(csv_field(assembly.log.curves[c].name) + ",")
        out.write_string(csv_field(assembly.run_names[source.run]) + ",")
        out.write_string(
          (if source.interpolated { "true" } else { "false" }) + ",",
        )
        out.write_string(assembly.log.rows[i][c].unwrap().to_string() + "\r\n")
      }
    }
  }
  out.to_string()
}

///|
/// Guard reports against caller mutation of the exposed arrays.
pub fn validate_assembly(assembly : Assembly) -> Unit raise WellError {
  validate(assembly.log)
  if assembly.sources.length() != assembly.log.rows.length() {
    fail("source row count mismatch")
  }
  for i in 0..<assembly.sources.length() {
    if assembly.sources[i].length() != assembly.log.curves.length() {
      fail("source column count mismatch")
    }
    if assembly.sources[i][0] is Some(_) {
      fail("synthetic depth cannot have source")
    }
    for c in 1..<assembly.log.curves.length() {
      match (assembly.log.rows[i][c], assembly.sources[i][c]) {
        (Some(_), Some(source)) =>
          if source.run < 0 || source.run >= assembly.run_names.length() {
            fail("invalid source run index")
          }
        (None, None) => ()
        _ => fail("source and sample presence differ")
      }
    }
  }
  for conflict in assembly.conflicts {
    if conflict.row < 0 ||
      conflict.row >= assembly.log.rows.length() ||
      conflict.kept_run < 0 ||
      conflict.kept_run >= assembly.run_names.length() ||
      conflict.incoming_run < 0 ||
      conflict.incoming_run >= assembly.run_names.length() ||
      !finite(conflict.depth) ||
      !finite(conflict.kept_value) ||
      !finite(conflict.incoming_value) {
      fail("invalid conflict record")
    }
  }
}
