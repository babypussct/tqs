#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const mode = process.argv[2];
const root = process.argv[3] && path.resolve(process.argv[3]);
if (!['--apply', '--check'].includes(mode) || !root) {
  console.error('Usage: node scripts/upstream-first-set-player-state-compat-guard.mjs --apply|--check <candidate-core-root>');
  process.exit(2);
}

const normalized = root.replaceAll(path.sep, '/');
if (!/(?:\/candidate-runtime\/packages\/freekill-core|\/candidate-source\/freekill-core|\/tqs-cardwire-qa-20261103-[^/]+\/packages\/freekill-core)$/.test(normalized)) {
  throw new Error('Refusing to write outside an isolated upstream-first candidate freekill-core root');
}

const file = path.join(root, 'lua/server/rpc/dispatchers.lua');
const before = 'local setPlayerState = function(params)\n' +
  '  if not (type(params[1]) == "number" and type(params[2]) == "number" and type(params[3] == "number")) then\n' +
  '    return false, nil\n' +
  '  end\n' +
  '\n' +
  '  local roomId = params[1]\n' +
  '  local playerId = params[2]\n' +
  '  local newState = params[3]\n' +
  '\n' +
  '  local room = GetRoom(roomId)\n' +
  '  if not room then\n' +
  '    return false, "internal_error", "Room not found"\n' +
  '  end';
const after = 'local setPlayerState = function(params)\n' +
  '  if not (type(params[1]) == "number" and type(params[2]) == "number" and type(params[3]) == "number") then\n' +
  '    return false, nil\n' +
  '  end\n' +
  '\n' +
  '  local roomId = params[1]\n' +
  '  local playerId = params[2]\n' +
  '  local newState = params[3]\n' +
  '\n' +
  '  local room = GetRoom(roomId)\n' +
  '  if not room then\n' +
  '    -- State notifications can race the scheduler\'s GameOver cleanup. The\n' +
  '    -- game room is already gone, so there is no Lua-side state to update.\n' +
  '    return true, false\n' +
  '  end';
const source = fs.readFileSync(file, 'utf8');

if (source.includes(after)) {
  if (source.includes(before)) throw new Error('Candidate SetPlayerState compatibility hunk is duplicated');
  console.log(`PASS isolated SetPlayerState compatibility guard ${mode}: already applied`);
  process.exit(0);
}

if (source.split(before).length !== 2) {
  throw new Error('Candidate dispatcher source diverged or compatibility hunk is ambiguous');
}
if (mode !== '--apply') {
  throw new Error('Candidate SetPlayerState compatibility hunk is missing; rerun with --apply');
}
fs.writeFileSync(file, source.replace(before, after));
console.log('PASS isolated SetPlayerState compatibility guard --apply: teardown no-op hunk installed');
