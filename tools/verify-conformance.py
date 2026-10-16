"""Independent Python structure/Decimal checker + public MoonBit CLI corpus.
Written from the documented CWLS baseline; does not call MoonBit to decide reference
validity and does not infer conformance from lasio's permissive reader. Not CWLS
Certify or an external certification. No network, private data or extra dependency.
"""
import argparse
import json
import re
import subprocess
import tempfile
from decimal import Decimal, localcontext
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
NUM=re.compile(r"[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\Z")
RESERVED=set("VW CPOA".replace(" ",""))
class Invalid(ValueError): pass
class Resource(ValueError): pass

def require(condition, message):
    if not condition: raise Invalid(message)

def independent_check(text):
    if len(text)>16000000: raise Resource("source budget")
    require(all(32<=ord(c)<=126 or c in "\r\n" for c in text),"ASCII")
    require("\n" not in text.replace("\r\n","") and "\r" not in text.replace("\r\n",""),"CRLF")
    lines=text.splitlines(keepends=True)
    if len(lines)>1000000: raise Resource("line budget")
    section=None; seen=[]; entries=[]; data=[]
    for line in lines:
        stripped=line.strip()
        if stripped.startswith("~"):
            require(len(stripped)>1,"section identifier")
            tag=stripped[1]
            require(section!="A","ASCII last")
            require(seen or tag=="V","Version first")
            require(tag not in RESERVED or tag not in seen,"section duplicate")
            section=tag; seen.append(tag)
        elif section=="A":
            require(stripped and not stripped.startswith("#"),"ASCII blank/comment")
            data.append((stripped.split(" "),len(line)))
        elif not stripped or stripped.startswith("#"): pass
        elif section in ("V","W","C","P"):
            body,colon,description=stripped.rpartition(":")
            left,dot,right=body.partition(".")
            unit,space,value=right.partition(" ")
            name=left.strip()
            require(colon and dot and space,"delimiters")
            require(name and not any(c in name for c in " .:"),"mnemonic")
            require(":" not in unit and " " not in unit,"unit")
            entries.append((section,name,unit,value.strip(),description.strip()))
        else: require(section is not None,"content before section")
    require(set("VWCA").issubset(seen),"required sections")
    if len(entries)>65536: raise Resource("entry budget")
    def header(section,name):
        values=[e for e in entries if e[0]==section and e[1]==name]
        require(len(values)==1,"missing/duplicate "+name)
        return values[0]
    def number(token):
        require(NUM.fullmatch(token),"decimal grammar")
        if len(token)>1024: raise Resource("numeric budget")
        return Decimal(token)
    vers=header("V","VERS"); wrap=header("V","WRAP")
    require(not vers[2] and number(vers[3])==2,"version")
    require(not wrap[2] and wrap[3] in ("YES","NO"),"wrap")
    curves=[e for e in entries if e[0]=="C"]
    require(curves,"curves")
    if len(curves)>4096: raise Resource("curve budget")
    index=curves[0]; require(index[1] in ("DEPT","DEPTH","TIME"),"index name")
    require(bool(index[2]) if index[1]=="TIME" else index[2] in ("M","F","FT"),"index unit")
    for name in ("COMP","WELL","FLD","LOC","SRVC","DATE"): header("W",name)
    keys={e[1] for e in entries if e[0]=="W"}
    if "PROV" in keys: header("W","PROV")
    else:
        for name in ("CNTY","STAT","CTRY"): header("W",name)
    require("UWI" in keys or "API" in keys,"identifier")
    for name in ("UWI","API"):
        if name in keys: header("W",name)
    nums={name:header("W",name) for name in ("STRT","STOP","STEP","NULL")}
    require(not nums["NULL"][2],"NULL unit")
    require(all(nums[k][2]==index[2] for k in ("STRT","STOP","STEP")),"grid units")
    start,stop,step,null=(number(nums[k][3]) for k in ("STRT","STOP","STEP","NULL"))
    rows=[]; pending=[]; width=len(curves)
    for tokens,physical in data:
        tokens=[t for t in tokens if t]
        if wrap[3]=="YES":
            require(physical<=80,"WRAP line width")
            require(pending or len(tokens)==1,"index alone")
            require(len(pending)+len(tokens)<=width,"wrapped overflow")
            pending.extend(number(t) for t in tokens)
            if len(pending)==width: rows.append(pending); pending=[]
        else:
            require(len(tokens)==width,"data width")
            rows.append([number(t) for t in tokens])
    require(not pending and rows,"complete records")
    axis=[row[0] for row in rows]
    require(all(x!=null for x in axis),"null index")
    require(axis[0]==start and axis[-1]==stop,"endpoints")
    with localcontext() as context:
        context.prec=4096
        deltas=[b-a for a,b in zip(axis,axis[1:])]
        require(not deltas or all(d>0 for d in deltas) or all(d<0 for d in deltas),"monotonic")
        require(index[1]!="TIME" or all(d>0 for d in deltas),"time direction")
        if step:
            require(all(d==step for d in deltas),"exact step")
            require(start%step==0 and stop%step==0,"integer grid")
    return True

def main():
    parser=argparse.ArgumentParser(); parser.add_argument("--reference-only",action="store_true")
    parser.add_argument("--output",type=Path); args=parser.parse_args()
    corpus=json.loads((ROOT/"fixtures/las2-conformance.json").read_text(encoding="utf-8"))
    counts=dict(cases=0,positive=0,negative=0,model_rejections=0,normalized_checked=0,archived_exact=0)
    with tempfile.TemporaryDirectory(prefix="moonwell-conformance-") as temp:
        request=Path(temp)/"request.json"
        def cli(command,text,expect_ok=True):
            request.write_text(json.dumps(dict(command=command,las=text)),encoding="utf-8")
            p=subprocess.run(["node","tools/moonwell.mjs",str(request)],cwd=ROOT,capture_output=True,text=True)
            result=json.loads(p.stdout)
            assert result["ok"]==expect_ok,(command,p.stdout,p.stderr)
            assert p.returncode==(0 if expect_ok else 1),(command,p.returncode)
            return result.get("result",result)
        for case in corpus["cases"]:
            reference=True; kind=None
            try: independent_check(case["las"])
            except Resource: reference=False; kind="resource"
            except Invalid: reference=False; kind="standard"
            assert reference==case["valid"],("reference",case["name"],kind)
            if not reference: assert kind==case["kind"],case["name"]
            counts["cases"]+=1; counts["positive" if reference else "negative"]+=1
            if args.reference_only: continue
            report=cli("validate-las2",case["las"])
            assert report["valid"]==reference,(case["name"],report)
            if not reference: assert any(d["kind"]==kind for d in report["diagnostics"]),(case["name"],report)
            archive=cli("archive-las2",case["las"])
            assert archive["las"]==case["las"],case["name"]
            counts["archived_exact"]+=1
            if reference and case["model"]:
                output=cli("strict-normalize",case["las"])["las"]
                independent_check(output)
                assert cli("validate-las2",output)["valid"]
                counts["normalized_checked"]+=1
            elif reference:
                error=cli("strict-normalize",case["las"],False)["error"]
                assert error.startswith("model:"),(case["name"],error)
                counts["model_rejections"]+=1
    result=dict(baseline=corpus["baseline"],reference="independent Python structure + Decimal",certification=False,**counts)
    if args.output: args.output.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result))
if __name__=="__main__": main()
