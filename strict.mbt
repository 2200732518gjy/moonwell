///|
priv struct StrictDataLine {
  number : Int
  text : String
  physical : Int
}

///|
priv struct StrictState {
  diagnostics : Array[LasDiagnostic]
  entries : Array[LasEntry]
  data : Array[StrictDataLine]
}

///|
fn strict_issue(
  state : StrictState,
  clause : String,
  section : String,
  line : Int,
  field : String,
  message : String,
  kind? : String = "standard",
) -> Unit {
  if state.diagnostics.length() < 256 {
    state.diagnostics.push({ kind, clause, section, line, field, message, })
  }
}

///|
fn strict_scan(document : LasDocument) -> StrictState {
  let state : StrictState = { diagnostics: [], entries: [], data: [], }
  let seen : Array[String] = []
  let mut section = ""
  let lines = document.source.split("\n").to_array()
  if lines.length() > 1000000 {
    strict_issue(
      state,
      "budget",
      "",
      0,
      "lines",
      "source exceeds 1000000 physical lines",
      kind="resource",
    )
    return state
  }
  for i in 0..<lines.length() {
    let raw = lines[i].to_owned()
    let terminated = i < lines.length() - 1
    if !terminated && raw == "" {
      continue
    }
    let number = i + 1
    if terminated && !raw.has_suffix("\r") {
      strict_issue(state, "3", section, number, "CRLF", "line must end CR LF")
    }
    let chars = raw.iter().to_array()
    for j in 0..<chars.length() {
      let c = chars[j].to_int()
      if c == 13 && terminated && j == chars.length() - 1 {
        continue
      }
      if c < 32 || c > 126 {
        strict_issue(
          state, "3", section, number, "ASCII", "only ASCII 32..126 and CRLF are permitted",
        )
        break
      }
    }
    let text = raw.trim().to_owned()
    if text.has_prefix("~") {
      if text.length() < 2 {
        strict_issue(
          state, "3", section, number, "section", "missing section identifier",
        )
        continue
      }
      let tag = text.iter().to_array()[1].to_string()
      if section == "A" {
        strict_issue(
          state, "3/5.8", "A", number, "section", "ASCII must be last",
        )
      }
      if seen.is_empty() && tag != "V" {
        strict_issue(
          state, "3/5.3", tag, number, "section", "Version must be first",
        )
      }
      if ["V", "W", "C", "P", "O", "A"].contains(tag) && seen.contains(tag) {
        strict_issue(
          state, "3", tag, number, "section", "reserved section may occur only once",
        )
      }
      section = tag
      seen.push(tag)
      continue
    }
    if section == "A" {
      if text == "" || text.has_prefix("#") {
        strict_issue(
          state, "5.1/5.8", "A", number, "record", "blank/comment lines are not allowed inside ASCII data",
        )
      } else {
        state.data.push({
          number,
          text,
          physical: raw.length() + (if terminated { 1 } else { 0 }),
        })
      }
    } else if text == "" || text.has_prefix("#") {
      continue
    } else if section == "" {
      strict_issue(
        state, "3", section, number, "section", "content precedes Version",
      )
    } else if ["V", "W", "C", "P"].contains(section) {
      state.entries.push({ section, line: number, header: parse_header(text), }) catch {
        WellError(message) =>
          strict_issue(state, "5.2", section, number, "header", message)
      }
    }
  }
  for tag in ["V", "W", "C", "A"] {
    if !seen.contains(tag) {
      strict_issue(state, "3", tag, 0, "section", "missing required section")
    }
  }
  state
}

///|
fn strict_headers(state : StrictState, section : String) -> Array[LasEntry] {
  state.entries.filter(e => e.section == section)
}

///|
fn strict_required(
  state : StrictState,
  section : String,
  name : String,
  clause : String,
) -> LasEntry? {
  let entries = state.entries.filter(e => {
    e.section == section && e.header.name == name
  })
  if entries.is_empty() {
    strict_issue(state, clause, section, 0, name, "missing required header")
    None
  } else {
    if entries.length() > 1 {
      strict_issue(
        state,
        clause,
        section,
        entries[1].line,
        name,
        "required header is ambiguous (duplicate)",
      )
    }
    Some(entries[0])
  }
}

///|
fn strict_number(state : StrictState, entry : LasEntry) -> LasDecimal? {
  if !decimal_grammar(entry.header.value) {
    strict_issue(
      state,
      "3/5.4",
      entry.section,
      entry.line,
      entry.header.name,
      "expected decimal without exponent",
    )
    None
  } else if entry.header.value.length() > 1024 {
    strict_issue(
      state,
      "budget",
      entry.section,
      entry.line,
      entry.header.name,
      "numeric token exceeds 1024 code units",
      kind="resource",
    )
    None
  } else {
    Some(exact_decimal(entry.header.value))
  }
}

///|
fn strict_well(
  state : StrictState,
  curves : Array[LasEntry],
) -> (LasDecimal?, LasDecimal?, LasDecimal?, LasDecimal?) {
  let numbers : Array[LasDecimal?] = []
  for name in ["STRT", "STOP", "STEP", "NULL"] {
    let entry = strict_required(state, "W", name, "5.4")
    match entry {
      None => numbers.push(None)
      Some(e) => {
        numbers.push(strict_number(state, e))
        if name == "NULL" {
          if e.header.unit != "" {
            strict_issue(state, "5.4", "W", e.line, name, "NULL has no unit")
          }
        } else if !curves.is_empty() && e.header.unit != curves[0].header.unit {
          strict_issue(
            state,
            "5.4",
            "W",
            e.line,
            name,
            "unit must match index channel exactly",
          )
        }
      }
    }
  }
  for name in ["COMP", "WELL", "FLD", "LOC", "SRVC", "DATE"] {
    ignore(strict_required(state, "W", name, "5.4"))
  }
  let well = strict_headers(state, "W")
  if well.any(e => e.header.name == "PROV") {
    ignore(strict_required(state, "W", "PROV", "5.4"))
  } else {
    for name in ["CNTY", "STAT", "CTRY"] {
      ignore(strict_required(state, "W", name, "5.4"))
    }
  }
  for name in ["UWI", "API"] {
    if well.any(e => e.header.name == name) {
      ignore(strict_required(state, "W", name, "5.4"))
    }
  }
  if !well.any(e => e.header.name == "UWI") &&
    !well.any(e => e.header.name == "API") {
    strict_issue(
      state, "5.4", "W", 0, "UWI/API", "one unique well identifier header is required (empty value is allowed)",
    )
  }
  (numbers[0], numbers[1], numbers[2], numbers[3])
}

///|
fn strict_data(
  state : StrictState,
  curves : Array[LasEntry],
  wrapped : Bool,
  start : LasDecimal?,
  stop : LasDecimal?,
  step : LasDecimal?,
  null : LasDecimal?,
) -> Unit {
  if curves.is_empty() {
    return
  }
  let mut column = 0
  let mut first : LasDecimal? = None
  let mut previous : LasDecimal? = None
  let mut direction = 0
  let mut rows = 0
  for line in state.data {
    let tokens = words(line.text)
    if wrapped {
      if line.physical > 80 {
        strict_issue(
          state,
          "5.3/5.8",
          "A",
          line.number,
          "line",
          "wrapped data line exceeds 80 characters including CRLF",
        )
      }
      if column == 0 && tokens.length() != 1 {
        strict_issue(
          state,
          "5.8",
          "A",
          line.number,
          "index",
          "wrapped index must be alone on its line",
        )
      }
      if column + tokens.length() > curves.length() {
        strict_issue(
          state,
          "5.8",
          "A",
          line.number,
          "width",
          "physical line crosses a wrapped record boundary",
        )
      }
    } else if tokens.length() != curves.length() {
      strict_issue(
        state,
        "5.5/5.8",
        "A",
        line.number,
        "width",
        "data width must equal curve count",
      )
    }
    for token in tokens {
      let valid = decimal_grammar(token)
      let within_budget = token.length() <= 1024
      if !valid {
        strict_issue(
          state,
          "3/5.8",
          "A",
          line.number,
          curves[column].header.name,
          "sample must be decimal without exponent",
        )
      } else if !within_budget {
        strict_issue(
          state,
          "budget",
          "A",
          line.number,
          curves[column].header.name,
          "numeric token exceeds 1024 code units",
          kind="resource",
        )
      }
      if column == 0 && valid && within_budget {
        let index = exact_decimal(token)
        if null is Some(n) && decimal_compare(index, n) == 0 {
          strict_issue(
            state,
            "5.5",
            "A",
            line.number,
            "index",
            "index cannot be NULL",
          )
        }
        if first is None {
          first = Some(index)
        }
        if previous is Some(p) {
          let sign = decimal_compare(index, p)
          if sign == 0 || (direction != 0 && sign != direction) {
            strict_issue(
              state,
              "3/5.4",
              "A",
              line.number,
              "index",
              "index must be strictly monotonic",
            )
          }
          if curves[0].header.name == "TIME" && sign <= 0 {
            strict_issue(
              state,
              "5.4",
              "A",
              line.number,
              "TIME",
              "time values must increase",
            )
          }
          direction = sign
          if step is Some(s) &&
            !s.coefficient.is_zero() &&
            decimal_compare(decimal_difference(index, p), s) != 0 {
            strict_issue(
              state,
              "5.4",
              "A",
              line.number,
              "STEP",
              "exact decimal interval differs from STEP; rounding is not allowed",
            )
          }
        }
        previous = Some(index)
        rows += 1
      }
      column = (column + 1) % curves.length()
    }
    if !wrapped {
      column = 0
    }
  }
  if column != 0 {
    strict_issue(state, "5.8", "A", 0, "record", "incomplete wrapped record")
  }
  if rows == 0 {
    strict_issue(
      state, "5.4/5.8", "A", 0, "record", "at least one indexed data record is required",
    )
  }
  if start is Some(a) && first is Some(b) && decimal_compare(a, b) != 0 {
    strict_issue(state, "5.4", "W", 0, "STRT", "must exactly equal first index")
  }
  if stop is Some(a) && previous is Some(b) && decimal_compare(a, b) != 0 {
    strict_issue(state, "5.4", "W", 0, "STOP", "must exactly equal last index")
  }
  if step is Some(s) && !s.coefficient.is_zero() {
    if start is Some(a) && !decimal_multiple(a, s) {
      strict_issue(
        state, "1/5.4", "W", 0, "STRT/STEP", "start divided by step must be an integer",
      )
    }
    if stop is Some(a) && !decimal_multiple(a, s) {
      strict_issue(
        state, "1/5.4", "W", 0, "STOP/STEP", "stop divided by step must be an integer",
      )
    }
  }
}

///|
/// CWLS January 2014 structural and exact-decimal validator, independent of Log.
/// An empty diagnostic array means this baseline passes within stated budgets,
/// not latest-edition certification or correctness of geological content.
pub fn check_las2(document : LasDocument) -> Array[LasDiagnostic] {
  let state = strict_scan(document)
  if state.diagnostics.any(d => d.kind == "resource") {
    return state.diagnostics
  }
  if state.entries.length() > 65536 || state.data.length() > 1000000 {
    strict_issue(
      state,
      "budget",
      "",
      0,
      "entries",
      "metadata/data record budget exceeded",
      kind="resource",
    )
    return state.diagnostics
  }
  for name in ["VERS", "WRAP"] {
    if strict_required(state, "V", name, "5.3") is Some(e) {
      if e.header.unit != "" {
        strict_issue(
          state,
          "5.3",
          "V",
          e.line,
          name,
          "required version field has no unit",
        )
      }
      if name == "VERS" {
        if !decimal_grammar(e.header.value) || e.header.value.length() > 1024 {
          strict_issue(state, "5.3", "V", e.line, name, "expected version 2.0")
        } else if decimal_compare(
            exact_decimal(e.header.value),
            exact_decimal("2"),
          ) !=
          0 {
          strict_issue(
            state,
            "5.3",
            "V",
            e.line,
            name,
            "only version 2.0 passes this baseline",
          )
        }
      } else if e.header.value != "YES" && e.header.value != "NO" {
        strict_issue(state, "5.3", "V", e.line, name, "WRAP must be YES or NO")
      }
    }
  }
  let curves = strict_headers(state, "C")
  if curves.is_empty() {
    strict_issue(
      state, "5.5", "C", 0, "index", "at least one index curve is required",
    )
  } else {
    let index = curves[0]
    if !["DEPT", "DEPTH", "TIME"].contains(index.header.name) {
      strict_issue(
        state,
        "5.5",
        "C",
        index.line,
        index.header.name,
        "index mnemonic must be DEPT, DEPTH or TIME",
      )
    }
    if index.header.name != "TIME" &&
      !["M", "F", "FT"].contains(index.header.unit) {
      strict_issue(
        state,
        "5.4",
        "C",
        index.line,
        "unit",
        "depth unit must be M, F or FT",
      )
    }
    if index.header.name == "TIME" && index.header.unit == "" {
      strict_issue(
        state,
        "5.4",
        "C",
        index.line,
        "unit",
        "time index must declare a numeric time unit",
      )
    }
  }
  if curves.length() > 4096 {
    strict_issue(
      state,
      "budget",
      "C",
      0,
      "curves",
      "document curve budget is 4096",
      kind="resource",
    )
    return state.diagnostics
  }
  let (start, stop, step, null) = strict_well(state, curves)
  let wrapped = state.entries.any(e => {
    e.section == "V" && e.header.name == "WRAP" && e.header.value == "YES"
  })
  strict_data(state, curves, wrapped, start, stop, step, null)
  state.diagnostics
}

///|
/// Refuses absent well metadata, off-grid decimal coordinates and other standard
/// violations. Never fabricates company/location/identifier or rounds observations.
pub fn write_las_strict(
  log : Log,
  wrapped? : Bool = false,
) -> String raise WellError {
  let text = write_las(log, wrapped~)
  let document = read_las_document(text)
  let errors = check_las2(document)
  if !errors.is_empty() {
    fail(conformance_error(errors[0]))
  }
  text
}
