"""Deterministic synthetic CWLS January-2014 rule corpus; no field data."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
BASE = ("~V\nVERS. 2.0 : version\nWRAP. NO : layout\n~W\n"
        "STRT.M 0 : start\nSTOP.M 2 : stop\nSTEP.M 1 : step\nNULL. -999.25 : null\n"
        "COMP. : company\nWELL. SYN:CASE : well\nFLD. : field\nLOC. : location\n"
        "PROV. : province\nSRVC. : service\nDATE. : date\nUWI. : identifier\n"
        "~C\nDEPT.M : depth\nGR.GAPI 07 010 01 00 : gamma\n~A\n0 10\n1 -999.25\n2 30\n").replace("\n", "\r\n")
cases = []
def add(name, text, valid=True, clauses=("3",), model=True, kind="standard"):
    cases.append(dict(name=name, las=text, valid=valid, clauses=list(clauses), model=model, kind=kind))
def mutate(name, old, new, valid=False, **kw):
    assert old in BASE, old
    add(name, BASE.replace(old, new), valid, **kw)
add("complete-empty-metadata-values", BASE, clauses=("3","5.2","5.3","5.4","5.5","5.8"))
add("no-final-terminator", BASE[:-2])
add("comments-and-predata-blanks", "# synthetic\r\n\r\n"+BASE.replace("~W", "# comment\r\n\r\n~W"), clauses=("5.1",))
mutate("regional-identifiers", "PROV. : province", "CNTY. : county\r\nSTAT. : state\r\nCTRY. : country", True, clauses=("5.4",))
mutate("api-instead-of-uwi", "UWI. : identifier", "API. : identifier", True, clauses=("5.4",))
mutate("equivalent-decimal-scales", "STRT.M 0", "STRT.M -0.0000", True, clauses=("5.4",))
mutate("opaque-codes-spaces-leading-zero", "07 010 01 00", "00  001 02 00", True, clauses=("5.5",))
mutate("missing-optional-api-code", "07 010 01 00", "", True, clauses=("5.5",))
mutate("legal-mnemonic-punctuation", "GR.GAPI", "GR/RAW+%_!$&*()[]{}.GAPI", True, clauses=("5.2","5.5"))
mutate("spaces-before-dot", "GR.GAPI", "  GR   .GAPI", True, clauses=("5.2",))
mutate("units-may-contain-dots", "GR.GAPI", "GR.G.API", True, clauses=("5.2",))
mutate("duplicate-curve-document", "GR.GAPI", "DEPT.GAPI", True, clauses=("5.5",), model=False)
mutate("customer-and-duplicate-parameter-document", "~A", "~P\r\nX. 1 : first\r\nX. 2 : second\r\n~Z customer\r\n# raw comment  \r\n\r\n  opaque payload  \r\n~A", True, clauses=("3","5.6","5.7"), model=False)
mutate("optional-other-unstructured", "~A", "~O\r\nraw text: dots.are.not.headers\r\n\r\n~A", True, clauses=("5.7",))
mutate("optional-parameter-values-with-colons", "~A", "~P\r\nRUN/ID. A:B:C : run\r\nVALUE.M +.125 : value\r\n~A", True, clauses=("5.2","5.6"))
mutate("extra-version-lines", "~W", "SOURCE. SYNTHETIC : source\r\n~W", True, clauses=("5.3",))
mutate("irregular-zero-step", "STEP.M 1", "STEP.M 0", True, clauses=("5.4",))
for unit in ("F","FT"):
    add("depth-unit-"+unit, BASE.replace(".M ", "."+unit+" "), clauses=("5.4",))
time = BASE.replace(".M ", ".S ").replace("DEPT.S", "TIME.S")
add("increasing-time", time, clauses=("5.4","5.5"))
down = BASE.replace("STRT.M 0", "STRT.M 2").replace("STOP.M 2", "STOP.M 0").replace("STEP.M 1", "STEP.M -1").replace("0 10", "2 10").replace("2 30", "0 30")
add("descending-depth", down, clauses=("5.4",))
add("descending-time", down.replace(".M ", ".S ").replace("DEPT.S", "TIME.S"), False, clauses=("5.4",))
wrapped = BASE.replace("WRAP. NO", "WRAP. YES").replace("0 10", "0\r\n10").replace("1 -999.25", "1\r\n-999.25").replace("2 30", "2\r\n30")
add("wrapped", wrapped, clauses=("5.3","5.8"))
add("wrapped-exact80", wrapped.replace("\r\n10\r\n", "\r\n"+" "*76+"10\r\n"), clauses=("5.8",))
add("wrapped-exact80-unterminated", wrapped[:-4]+" "*78+"30", clauses=("5.8",))
add("wrapped-too-wide-padding", wrapped.replace("\r\n10\r\n", "\r\n"+" "*77+"10\r\n"), False, clauses=("5.8",))
add("wrapped-index-not-alone", wrapped.replace("0\r\n10", "0 10"), False, clauses=("5.8",))
add("wrapped-incomplete-record", wrapped.replace("2\r\n30", "2"), False, clauses=("5.8",))
add("wrapped-cross-record", wrapped.replace("10\r\n1", "10 1"), False, clauses=("5.8",))
for name in ("VERS","WRAP","STRT","STOP","STEP","NULL","COMP","WELL","FLD","LOC","SRVC","DATE"):
    add("missing-header-"+name, "\r\n".join(x for x in BASE.split("\r\n") if not x.startswith(name+".")), False, clauses=("5.3" if name in ("VERS","WRAP") else "5.4",))
for name in ("VERS","WRAP","STRT","COMP","PROV","UWI"):
    line = next(x for x in BASE.split("\r\n") if x.startswith(name+"."))
    mutate("duplicate-required-"+name, line, line+"\r\n"+line, clauses=("5.3" if name in ("VERS","WRAP") else "5.4",))
mutate("regional-alternative-missing", "PROV. : province", "CNTY. : county\r\nSTAT. : state", clauses=("5.4",))
mutate("identifier-missing", "UWI. : identifier\r\n", "", clauses=("5.4",))
mutate("invalid-version", "VERS. 2.0", "VERS. 3.0", clauses=("5.3",))
mutate("version-unit", "VERS. 2.0", "VERS.M 2.0", clauses=("5.3",))
mutate("invalid-wrap", "WRAP. NO", "WRAP. MAYBE", clauses=("5.3",))
mutate("wrap-unit", "WRAP. NO", "WRAP.M NO", clauses=("5.3",))
mutate("invalid-depth-name", "DEPT.M", "INDEX.M", clauses=("5.5",))
mutate("invalid-depth-unit", "DEPT.M", "DEPT.CM", clauses=("5.4",))
mutate("mismatched-grid-unit", "STEP.M 1", "STEP.FT 1", clauses=("5.4",))
mutate("null-unit", "NULL. -999.25", "NULL.M -999.25", clauses=("5.4",))
for name,old,new in (("endpoint-start","STRT.M 0","STRT.M 1"),("endpoint-stop","STOP.M 2","STOP.M 3"),("wrong-step","STEP.M 1","STEP.M 0.5"),("step-rounding","1 -999.25","1.000000000000000000001 -999.25"),("endpoint-rounding","STOP.M 2","STOP.M 2.000000000000000000001")):
    mutate(name,old,new,clauses=("1","5.4"))
off = BASE.replace("STRT.M 0","STRT.M 0.25").replace("STOP.M 2","STOP.M 1.25").replace("STEP.M 1","STEP.M 0.5").replace("0 10","0.25 10").replace("1 -999.25","0.75 -999.25").replace("2 30","1.25 30")
add("off-grid-integer-quotient",off,False,clauses=("1","5.4"))
for token in ("1e0","NaN","inf","1,0","1_0","--1","1.2.3","+","."):
    mutate("invalid-number-"+token,"1 -999.25",token+" -999.25",clauses=("3","5.8"))
mutate("index-null", "NULL. -999.25", "NULL. 0", clauses=("5.5",))
mutate("repeated-index", "1 -999.25", "0 -999.25", clauses=("5.4",))
mutate("reversed-index", "1 -999.25", "3 -999.25", clauses=("5.4",))
mutate("ragged-row", "1 -999.25", "1", clauses=("5.5","5.8"))
mutate("extra-column", "1 -999.25", "1 2 3", clauses=("5.5","5.8"))
mutate("data-comment", "1 -999.25", "# comment\r\n1 -999.25", clauses=("5.1","5.8"))
mutate("data-blank", "1 -999.25", "\r\n1 -999.25", clauses=("5.8",))
for flag in ("V","W","C","A"):
    # Remove section with its body up to the next section.
    lines=BASE.splitlines(keepends=True); out=[]; skip=False
    for line in lines:
        if line.startswith("~"): skip=line.startswith("~"+flag)
        if not skip: out.append(line)
    add("missing-section-"+flag,"".join(out),False,clauses=("3",))
for flag in ("V","W","C","P","O","A"):
    if flag in ("P","O"):
        mutate("duplicate-section-"+flag,"~A","~"+flag+"\r\n~"+flag+"\r\n~A",clauses=("3",))
    else:
        mutate("duplicate-section-"+flag,"~"+flag,"~"+flag+"\r\n~"+flag,clauses=("3",))
add("section-after-ascii",BASE+"~O\r\ntext\r\n",False,clauses=("3","5.8"))
mutate("version-not-first","~V","~Z customer\r\n~V",clauses=("3","5.3"))
mutate("lowercase-reserved-marker","~V","~v",clauses=("5.1",))
for old,new,label in (("GR.GAPI","GR GAPI","dot"),("GR.GAPI 07 010 01 00 : gamma","GR.GAPI:gamma","space"),("GR.GAPI 07 010 01 00 : gamma","GR.GAPI 07 010 01 00 gamma","colon"),("GR.GAPI","G R.GAPI","mnemonic-space")):
    mutate("header-delimiter-"+label,old,new,clauses=("5.2",))
for char,label in (("\t","tab"),("é","non-ascii"),("\x00","nul"),("\r","bare-cr")):
    mutate("encoding-"+label,"SYN:CASE","SYN"+char+"CASE",clauses=("3",))
add("lf-not-crlf",BASE.replace("\r\n","\n"),False,clauses=("3",))
mutate("large-decimal-model-limit","0 10","0 "+"9"*400,True,clauses=("3","5.8"),model=False)
mutate("underflow-model-limit","0 10","0 0."+"0"*400+"1",True,clauses=("3","5.8"),model=False)
mutate("false-null-model-limit","0 10","0 -999.250000000000000000000001",True,clauses=("3","5.8"),model=False)
mutate("numeric-resource-limit","0 10","0 "+"9"*1025,False,clauses=("budget",),kind="resource",model=False)
assert len({c["name"] for c in cases})==len(cases)
output=ROOT/"fixtures/las2-conformance.json"
output.write_text(json.dumps({"baseline":"CWLS LAS 2.0 January 2014","synthetic":True,"cases":cases},ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"cases":len(cases),"positive":sum(c["valid"] for c in cases),"negative":sum(not c["valid"] for c in cases)}))
