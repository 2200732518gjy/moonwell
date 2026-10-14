///|
fn field(request : Json, name : String) -> Json raise WellError {
  match request {
    Object(map) =>
      match map.get(name) {
        Some(value) => value
        None => {
          fail("missing field: " + name)
          Json::null()
        }
      }
    _ => {
      fail("request must be an object")
      Json::null()
    }
  }
}

///|
fn string_field(request : Json, name : String) -> String raise WellError {
  match field(request, name) {
    String(value) => value
    _ => {
      fail("expected string: " + name)
      ""
    }
  }
}

///|
fn number_field(request : Json, name : String) -> Double raise WellError {
  match field(request, name) {
    Number(value, ..) => {
      if !finite(value) {
        fail("nonfinite field: " + name)
      }
      value
    }
    _ => {
      fail("expected number: " + name)
      0.0
    }
  }
}

///|
fn array_field(request : Json, name : String) -> Array[Json] raise WellError {
  match field(request, name) {
    Array(values) => values
    _ => {
      fail("expected array: " + name)
      []
    }
  }
}

///|
fn request_grid(request : Json) -> Array[Double] raise WellError {
  depth_grid(
    number_field(request, "start"),
    number_field(request, "stop"),
    number_field(request, "step"),
  )
}

///|
fn check_fields(
  request : Json,
  allowed : Array[String],
) -> Unit raise WellError {
  match request {
    Object(map) =>
      for name, _ in map {
        if !allowed.contains(name) {
          fail("unknown request field: " + name)
        }
      }
    _ => fail("request must be object")
  }
}

///|
/// Stateless JSON protocol. All domain work is implemented here, not in the IO adapter.
pub fn dispatch(request : Json) -> Json raise WellError {
  let command = string_field(request, "command")
  match command {
    "qa" => {
      check_fields(request, ["command", "las", "max_gap"])
      quality_report(
        parse(string_field(request, "las")),
        [],
        number_field(request, "max_gap"),
      )
    }
    "normalize" => {
      check_fields(request, ["command", "las"])
      Json::object({
        "las": Json::string(
          write_las(ascending(parse(string_field(request, "las")))),
        ),
      })
    }
    "csv" => {
      check_fields(request, ["command", "las"])
      Json::object({
        "csv": Json::string(write_csv(parse(string_field(request, "las")))),
      })
    }
    "resample" => {
      check_fields(request, [
        "command", "las", "start", "stop", "step", "max_gap",
      ])
      let result = resample(
        parse(string_field(request, "las")),
        request_grid(request),
        number_field(request, "max_gap"),
      )
      Json::object({
        "las": Json::string(write_las(result)),
        "csv": Json::string(write_csv(result)),
      })
    }
    "interval" => {
      check_fields(request, [
        "command", "las", "curve", "start", "stop", "max_gap",
      ])
      interval_report(
        summarize_interval(
          parse(string_field(request, "las")),
          string_field(request, "curve"),
          number_field(request, "start"),
          number_field(request, "stop"),
          number_field(request, "max_gap"),
        ),
      )
    }
    "assemble" => {
      check_fields(request, [
        "command", "runs", "start", "stop", "step", "max_gap", "policy", "tolerance",
      ])
      let run_requests = array_field(request, "runs")
      if run_requests.length() == 0 || run_requests.length() > 64 {
        fail("invalid run count")
      }
      let runs : Array[Log] = []
      let names : Array[String] = []
      for run in run_requests {
        check_fields(run, ["name", "las"])
        names.push(string_field(run, "name"))
        runs.push(parse(string_field(run, "las")))
      }
      let policy = match string_field(request, "policy") {
        "reject" => Reject
        "first" => PreferFirst
        "last" => PreferLast
        _ => {
          fail("policy must be reject, first or last")
          Reject
        }
      }
      let result = assemble(
        runs,
        names,
        request_grid(request),
        number_field(request, "max_gap"),
        policy,
        tolerance=number_field(request, "tolerance"),
      )
      Json::object({
        "las": Json::string(write_las(result.log)),
        "csv": Json::string(write_csv(result.log)),
        "provenance_csv": Json::string(provenance_csv(result)),
        "assembly": assembly_report(result),
      })
    }
    _ => {
      fail("unknown command: " + command)
      Json::null()
    }
  }
}

///|
/// A request yields exactly one JSON envelope, including recoverable input errors.
pub fn execute(text : String) -> String {
  let response = try {
    let result = dispatch(read_report(text))
    Json::object({ "ok": Json::boolean(true), "result": result })
  } catch {
    WellError(message) =>
      Json::object({
        "ok": Json::boolean(false),
        "error": Json::string(message),
      })
  }
  response.stringify()
}
