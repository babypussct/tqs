// Install the candidate-only QA pre-draw hook at the Hegemony wire boundary.
// The hook is inert unless the isolated tqs_qa package installs the matching
// method; production/current runtimes do not contain this candidate delta.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const [mode, rootInput] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && rootInput,
  'expected --apply|--check <isolated-candidate-hegemony>');
const root = fs.realpathSync(rootInput);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/hegemony$/u,
  'Hegemony pre-draw guard is restricted to an isolated candidate');
const target = path.join(root, 'pkg/gamemodes/new_hegemony_mode.lua');
assert.equal(fs.realpathSync(target), target, 'candidate Hegemony mode must not be a symlink');

const body = `function HegLogic:prepareDrawPile()
  local preDrawHook = self.room.__tqs_qa_beforePrepareDrawPile
  if type(preDrawHook) == "function" then
    preDrawHook(self.room)
  end
  GameLogic.prepareDrawPile(self)
`;
const source = fs.readFileSync(target, 'utf8');
if (!source.includes(body)) {
  assert.equal(mode, '--apply', 'candidate Hegemony mode is missing the QA pre-draw hook');
  const anchor = `function HegLogic:prepareDrawPile()\n  GameLogic.prepareDrawPile(self)\n`;
  assert.equal(source.split(anchor).length, 2, 'Hegemony pre-draw anchor drifted');
  fs.writeFileSync(target, source.replace(anchor, body));
}
const installed = fs.readFileSync(target, 'utf8');
assert.equal(installed.split(body).length, 2,
  'Hegemony pre-draw hook must occur exactly once');
console.log(`PASS isolated Hegemony card-wire pre-draw hook ${mode}; v1 remains QA-only`);
