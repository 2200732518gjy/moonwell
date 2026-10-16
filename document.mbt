///|
/// Immutable source archive. Retains exact line endings, comments, duplicates,
/// section order and numeric spelling; construction is not a conformance claim.
pub struct LasDocument {
  source : String
}

///|
pub(all) struct LasEntry {
  section : String
  line : Int
  header : Header
}

///|
pub(all) struct LasDiagnostic {
  kind : String
  clause : String
  section : String
  line : Int
  field : String
  message : String
}

///|
/// Bounded capture, including invalid documents for diagnostics and repair.
pub fn read_las_document(text : String) -> LasDocument raise WellError {
  if text.length() > 16000000 {
    fail("resource: source exceeds 16000000 code units")
  }
  { source: text, }
}

///|
/// Exact original text, never a regenerated interpretation of the source.
pub fn document_text(document : LasDocument) -> String {
  document.source
}

///|
/// Ordered header entries, including duplicate names. Use check_las2 first if
/// conformance matters; an unparseable header is an error, never silently dropped.
pub fn document_entries(
  document : LasDocument,
) -> Array[LasEntry] raise WellError {
  let entries : Array[LasEntry] = []
  let mut section = ""
  let mut number = 0
  for raw in document.source.split("\n") {
    number += 1
    let text = raw.trim().to_owned()
    if text.has_prefix("~") && text.length() >= 2 {
      section = text.iter().to_array()[1].to_string().to_upper()
    } else if text != "" &&
      !text.has_prefix("#") &&
      ["V", "W", "C", "P"].contains(section) {
      entries.push({ section, line: number, header: parse_header(text), })
    }
  }
  entries
}

///|
fn conformance_error(d : LasDiagnostic) -> String {
  d.kind +
  ": LAS2 " +
  d.clause +
  " ~" +
  d.section +
  " line " +
  d.line.to_string() +
  " " +
  d.field +
  ": " +
  d.message
}

///|
/// Strict standard validation is separate from the unique-column finite-Double
/// analysis model. Legal duplicates/extreme numbers remain available in source.
pub fn document_to_log(document : LasDocument) -> Log raise WellError {
  let diagnostics = check_las2(document)
  if diagnostics.length() > 0 {
    fail(conformance_error(diagnostics[0]))
  }
  try {
    let state = strict_scan(document)
    let null_entries = state.entries.filter(e => {
      e.section == "W" && e.header.name == "NULL"
    })
    if !null_entries.is_empty() {
      let entry = null_entries[0]
      let exact_null = exact_decimal(entry.header.value)
      let numeric_null = parse_number(entry.header.value)
      for line in state.data {
        for token in words(line.text) {
          let numeric = parse_number(token)
          if numeric == numeric_null &&
            decimal_compare(exact_decimal(token), exact_null) != 0 {
            fail(
              "sample would collapse onto NULL after Double conversion at line " +
              line.number.to_string(),
            )
          }
        }
      }
    }
    parse(document.source)
  } catch {
    WellError(message) => {
      fail("model: valid LAS2 document cannot enter Log: " + message)
      abort("unreachable")
    }
  }
}

///|
pub fn parse_strict(text : String) -> Log raise WellError {
  document_to_log(read_las_document(text))
}

///|
/// Returns structured diagnostics; compatibility parse() never implies this check.
pub fn las2_report(document : LasDocument) -> Json {
  let diagnostics = check_las2(document)
  Json::object({
    "baseline": Json::string("CWLS LAS 2.0 January 2014"),
    "valid": Json::boolean(diagnostics.is_empty()),
    "diagnostics": Json::array(
      diagnostics.map(d => {
        Json::object({
          "kind": Json::string(d.kind),
          "clause": Json::string(d.clause),
          "section": Json::string(d.section),
          "line": Json::number(d.line.to_double()),
          "field": Json::string(d.field),
          "message": Json::string(d.message),
        })
      }),
    ),
  })
}
