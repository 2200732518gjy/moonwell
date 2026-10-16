"""Independent metadata oracle, not LAS conformance certification.
Requires lasio==0.32; run after release JS build. Synthetic fixtures only.
"""
import io
import json
import pathlib
import subprocess
import tempfile
import lasio

root = pathlib.Path(__file__).resolve().parents[1]
base = (root / "fixtures/las2-api-codes.las").read_text(encoding="ascii")
cases = [base, base.replace("GR.GAPI", "GR/RAW+.GAPI"),
         base.replace("45 310 01 00", ""),
         base.replace("45 310 01 00", "00 001 00 00"),
         base.replace("07 010 01 00", "07  010 01 00"),
         base.replace("WRAP. NO", "WRAP. YES").replace(
             "0 10 1\n1 -999.25 2\n2 30 3", "0\n10 1\n1\n-999.25 2\n2\n30 3")]
def without_customer_sections(text):
    # lasio 0.32 treats this opaque section as formatted headers and rejects it.
    # Exclude ONLY customer payload from its oracle input; MoonWell still sees it.
    lines, skip = [], False
    for line in text.splitlines():
        if line.startswith("~"):
            skip = line.startswith("~X")
        if not skip:
            lines.append(line)
    return "\n".join(lines) + "\n"

for i, text in enumerate(cases):
    reference = lasio.read(io.StringIO(without_customer_sections(text)), engine="normal")
    with tempfile.TemporaryDirectory(prefix="moonwell-standard-") as temp:
        request = pathlib.Path(temp) / "request.json"
        request.write_text(json.dumps({"command": "normalize", "las": text}), encoding="utf-8")
        p = subprocess.run(["node", "tools/moonwell.mjs", str(request)], cwd=root,
                           capture_output=True, text=True, check=True)
        result = json.loads(p.stdout)
        assert result["ok"], result
        output = result["result"]["las"]
        actual = lasio.read(io.StringIO(without_customer_sections(output)), engine="normal")
        for expected, observed in zip(reference.curves, actual.curves):
            assert expected.mnemonic == observed.mnemonic, i
            assert str(expected.value) == str(observed.value), (i, expected, observed)
        assert len(reference.curves) == len(actual.curves), i
        assert reference.well["WELL"].value == actual.well["WELL"].value == "SYN:CASE", i
        assert "~X Synthetic customer section" in output, i
        assert "SOURCE. SYNTHETIC" in output, i
print(json.dumps({"oracle": "lasio", "version": lasio.__version__,
                  "metadata_cases": len(cases), "matched": len(cases),
                  "certification": False, "oracle_excludes": ["opaque customer sections"]}))
