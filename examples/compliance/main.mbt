///|
fn main {
  try {
    let text = "~V\nVERS. 2.0 : version\nWRAP. NO : wrap\n~W\nSTRT.M 0 : start\nSTOP.M 1 : stop\nSTEP.M 1 : step\nNULL. -999.25 : missing\n~C\nDEPT.M : depth\nGR.GAPI 45 310 01 00 : gamma\n~A\n0 10\n1 20\n"
    let log = @well.parse(text)
    assert_eq(log.curves[1].api_code, "45 310 01 00")
    let renamed = @well.rename_curve(log, "GR", "GR/RAW+")
    let selected = @well.select(renamed, ["GR/RAW+"])
    let converted = @well.convert_curve(selected, "DEPT", "FT")
    let result = @well.parse(@well.write_las(converted, wrapped=true))
    assert_eq(result.curves[1].api_code, "45 310 01 00")
    assert_eq(result.curves[1].name, "GR/RAW+")
    assert_eq(result.rows.length(), 2)
    println(
      "LAS2 API-code parse -> select/rename/unit-convert -> wrapped write -> parse passed",
    )
  } catch {
    error => abort(error.to_string())
  }
}
