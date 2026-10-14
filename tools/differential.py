"""Optional independent LAS2 numerical oracle: lasio==0.32, numpy==2.3.5.
Synthetic fixtures only; lasio is not a production dependency or code source.
Run after moon build --target js --release --deny-warn.
"""
import io
import json
import pathlib
import random
import subprocess
import tempfile
import lasio
import numpy as np

root = pathlib.Path(__file__).resolve().parents[1]
rng = random.Random(20261014)
for case in range(32):
    n = 3 + case % 10
    columns = 1 + case % 4
    wrapped = case % 2 == 1 and columns > 2
    step = -0.5 if case % 4 >= 2 else 0.5
    depths = [10 + i * step for i in range(n)]
    data = [[d] + [(-999.25 if rng.randrange(5) == 0 else rng.randint(-100, 100) / 8) for _ in range(columns - 1)] for d in depths]
    lines = ['~Version', 'VERS. 2.0 : version', 'WRAP. ' + ('YES' if wrapped else 'NO') + ' : wrap', '~Well',
             'STRT.M %s : start' % depths[0], 'STOP.M %s : stop' % depths[-1], 'STEP.M %s : step' % step,
             'NULL. -999.25 : null', 'WELL. SYNTHETIC : generated test', '~Curve', 'DEPT.M : depth']
    lines += ['C%s.GAPI : synthetic' % i for i in range(1, columns)]
    lines += ['~Parameter', 'RUN. 1 : test run', '~Other', 'hand-authored synthetic schema', '~ASCII']
    for row in data:
        if wrapped and columns > 1:
            lines += [str(row[0]), ' '.join(map(str, row[1:]))]
        else:
            lines += [' '.join(map(str, row))]
    text = '\n'.join(lines) + '\n'
    reference = lasio.read(io.StringIO(text), engine='normal').data
    with tempfile.TemporaryDirectory(prefix='moonwell-oracle-') as temp:
        request = pathlib.Path(temp) / 'request.json'
        request.write_text(json.dumps({'command': 'normalize', 'las': text}), encoding='utf-8')
        result = subprocess.run(['node', 'tools/moonwell.mjs', str(request)], cwd=root, capture_output=True, text=True, check=True)
        envelope = json.loads(result.stdout)
        assert envelope['ok'], envelope
        normalized = envelope['result']['las']
        observed = lasio.read(io.StringIO(normalized), engine='normal').data
        expected = reference[::-1] if step < 0 else reference
        assert np.array_equal(observed, expected, equal_nan=True), 'oracle mismatch case %s' % case
        assert len(lasio.read(io.StringIO(normalized)).curves) == columns
print(json.dumps({'oracle': 'lasio', 'version': lasio.__version__, 'numpy': np.__version__, 'synthetic_cases': 32, 'matched': 32, 'seed': 20261014}))

