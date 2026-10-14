"""Conservative physical production-line and non-empty engineering history audit."""
import argparse
import json
import pathlib
import subprocess

root = pathlib.Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--minimum-lines', type=int, default=1500)
p.add_argument('--minimum-commits', type=int, default=20)
a = p.parse_args()
files = {}
for path in root.glob('*.mbt'):
    if path.name.endswith(('_test.mbt', '_wbtest.mbt')):
        continue
    # Exclude blanks, comment-only lines, and block delimiters; count actual source.
    count = sum(bool(line.strip()) and not line.lstrip().startswith('//')
                for line in path.read_text(encoding='utf-8-sig').splitlines())
    files[path.name] = count
history = subprocess.check_output(['git', 'rev-list', '--reverse', 'HEAD'], cwd=root, text=True).splitlines()
commits = []
for sha in history:
    paths = subprocess.check_output(['git', 'diff-tree', '--root', '--no-commit-id', '--name-only', '-r', sha], cwd=root, text=True).splitlines()
    if paths:
        commits.append(sha)
result = {'production_lines': sum(files.values()), 'files': files,
          'nonempty_commits': len(commits), 'commits': commits,
          'excluded': ['tests', 'examples', 'bridge', 'generated interfaces', 'JS adapters', 'comments', 'blank lines'],
          'note': 'Nonempty count is a mechanical upper bound; human review must reject artificial slices.'}
print(json.dumps(result, indent=2))
if result['production_lines'] < a.minimum_lines or len(commits) < a.minimum_commits:
    raise SystemExit('audit threshold not met')
