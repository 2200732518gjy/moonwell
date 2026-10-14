#!/usr/bin/env node
// IO-only adapter. Parsing, QA, alignment, conflicts and serialization are MoonBit.
import { readFileSync, statSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const require = createRequire(import.meta.url);
const root = fileURLToPath(new URL('../', import.meta.url));
const args = process.argv.slice(2);
if (args.length < 1 || args.length > 2) {
  console.error('Usage: node tools/moonwell.mjs REQUEST.json [RESPONSE.json]');
  process.exit(2);
}
try {
  const inputPath = path.resolve(args[0]);
  if (!statSync(inputPath).isFile() || statSync(inputPath).size > 16000000) throw new Error('request must be a file <= 16 MB');
  globalThis.__moonwellInput = readFileSync(inputPath, 'utf8');
  const artifact = path.join(root, '_build/js/release/build/cmd/bridge/bridge.js');
  // Redirect exactly the one MoonBit envelope, never implement domain operations here.
  let response = '';
  const originalWrite = process.stdout.write;
  process.stdout.write = (chunk) => { response += chunk; return true; };
  try { require(artifact); } finally { process.stdout.write = originalWrite; }
  const envelope = JSON.parse(response);
  if (args[1]) writeFileSync(path.resolve(args[1]), response, { flag: 'wx', encoding: 'utf8' });
  else process.stdout.write(response);
  if (!envelope.ok) process.exitCode = 1;
} catch (error) {
  console.error(error.message);
  process.exitCode = 2;
} finally {
  delete globalThis.__moonwellInput;
}
