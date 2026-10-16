///|
fn main {
  try {
    let source = "~V\r\nVERS. 2.0 : version\r\nWRAP. NO : layout\r\n~W\r\nSTRT.M 0 : start\r\nSTOP.M 2 : stop\r\nSTEP.M 1 : step\r\nNULL. -999.25 : null\r\nCOMP. : company\r\nWELL. SYN:CASE : well\r\nFLD. : field\r\nLOC. : location\r\nPROV. : province\r\nSRVC. : service\r\nDATE. : date\r\nUWI. : identifier\r\n~C\r\nDEPT.M : depth\r\nGR.GAPI 07 010 01 00 : gamma\r\n~A\r\n0 10\r\n1 -999.25\r\n2 30\r\n"
    let doc = @well.read_las_document(source)
    assert_eq(@well.document_text(doc), source)
    assert_eq(@well.check_las2(doc).length(), 0)
    let log = @well.document_to_log(doc)
    for wrapped in [false, true] {
      let output = @well.write_las_strict(log, wrapped~)
      assert_eq(@well.check_las2(@well.read_las_document(output)).length(), 0)
      assert_eq(@well.parse_strict(output).curves[1].api_code, "07 010 01 00")
    }
    let duplicate = source.replace(old="GR.GAPI", new="DEPT.GAPI")
    let archive = @well.read_las_document(duplicate)
    assert_eq(@well.check_las2(archive).length(), 0)
    assert_eq(@well.document_text(archive), duplicate)
    assert_eq(
      @well.document_entries(archive).filter(e => e.section == "C").length(),
      2,
    )
    let limited = try {
      ignore(@well.document_to_log(archive))
      false
    } catch {
      @well.WellError(message) => message.has_prefix("model:")
    }
    assert_true(limited)
    let invalid = source.replace(old="COMP. : company\r\n", new="")
    let errors = @well.check_las2(@well.read_las_document(invalid))
    assert_true(errors.any(d => d.kind == "standard" && d.field == "COMP"))
    println(
      "LAS2 strict validate -> analyze -> write both WRAPs; exact archive; model/standard diagnostics passed",
    )
  } catch {
    error => abort(error.to_string())
  }
}
