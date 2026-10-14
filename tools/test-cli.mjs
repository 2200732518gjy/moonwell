import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
const dir = mkdtempSync(path.join(tmpdir(), 'moonwell-cli-'));
const run = (...args) => spawnSync(process.execPath, ['tools/moonwell.mjs', ...args], { encoding: 'utf8' });
try {
  const qa = run('fixtures/qa.json');
  assert.equal(qa.status, 0, qa.stderr);
  assert.equal(JSON.parse(qa.stdout).result.schema, 'moonwell.qa/v1');
  const assembly = run('fixtures/assemble.json');
  assert.equal(assembly.status, 0, assembly.stderr);
  const report = JSON.parse(assembly.stdout).result;
  assert.equal(report.assembly.conflicts.length, 1);
  assert.equal(report.assembly.sources[0][1].run, 1);
  assert.match(report.las, /0 11/);
  const invalid = path.join(dir, 'bad.json');
  writeFileSync(invalid, '{bad}');
  const bad = run(invalid);
  assert.equal(bad.status, 1);
  assert.equal(JSON.parse(bad.stdout).ok, false);
  const output = path.join(dir, 'result.json');
  assert.equal(run('fixtures/qa.json', output).status, 0);
  const before = readFileSync(output, 'utf8');
  assert.equal(run('fixtures/qa.json', output).status, 2);
  assert.equal(readFileSync(output, 'utf8'), before);
  console.log('CLI: QA, assembly, invalid request and no-overwrite checks passed');
} finally { rmSync(dir, { recursive: true, force: true }); }
