///|
/// Three complete downstream workflows, using only the published public API.
fn main {
  try {
    let curves : Array[@well.Curve] = [
      { name: "DEPT", unit: "M", description: "depth", api_code: "", },
      { name: "GR", unit: "GAPI", description: "gamma ray", api_code: "", },
    ]
    let acquisition = @well.make_log(curves, [
      [Some(0.0), Some(10.0)],
      [Some(1.0), None],
      [Some(2.0), Some(30.0)],
    ])
    // Acquisition QA: text input -> validation + explicit rule -> report.
    let decoded = @well.parse(@well.write_las(acquisition))
    let rules = [
      @well.QcRule::{
        curve: "GR",
        minimum: Some(0.0),
        maximum: Some(150.0),
        max_gradient: Some(30.0),
        constant_run: 3,
      },
    ]
    let issues = @well.quality_check(decoded, rules, 2.0)
    if issues.length() != 1 {
      abort("unexpected QA findings")
    }
    println(@well.report_text(@well.quality_report(decoded, rules, 2.0)))
    // Research pipeline: explicit fill + depth grid -> integration and numerical CSV.
    let filled = @well.fill_linear(decoded, "GR", 2.0)
    let sampled = @well.resample(filled, @well.depth_grid(0.0, 2.0, 0.5), 1.0)
    let interval = @well.summarize_interval(sampled, "GR", 0.0, 2.0, 1.0)
    if (interval.integral - 40.0).abs() > 0.000001 {
      abort("unexpected integral")
    }
    println(@well.write_csv(sampled))
    // Archive integration: two runs -> explicit policy -> LAS + cell lineage.
    let second = @well.make_log(curves, [
      [Some(0.0), Some(11.0)],
      [Some(1.0), Some(20.0)],
      [Some(2.0), Some(30.0)],
    ])
    let assembled = @well.assemble(
      [decoded, second],
      ["acquisition", "repeat"],
      [0.0, 1.0, 2.0],
      1.0,
      PreferLast,
    )
    if assembled.conflicts.length() != 1 {
      abort("unexpected conflict count")
    }
    if assembled.sources[1][1].unwrap().run != 1 {
      abort("incorrect lineage")
    }
    println(@well.write_las(assembled.log))
    println(@well.report_text(@well.assembly_report(assembled)))
    println("MoonWell downstream workflows passed")
  } catch {
    @well.WellError(message) => abort(message)
  }
}
