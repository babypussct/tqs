import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function updateRequestVisibility(core, mode) {
  const target = path.join(core, 'ltk/core/card_wire_request_visibility.lua');
  assert.equal(fs.realpathSync(path.dirname(target)), path.dirname(target), 'Symlinked client core');
  const reviewed = fs.readFileSync(fileURLToPath(new URL('../qa/card-wire-request-visibility.lua', import.meta.url)));
  if (!fs.existsSync(target)) {
    assert.equal(mode, '--apply', 'Request visibility module is missing');
    fs.writeFileSync(target, reviewed, { flag: 'wx' });
  }
  assert.equal(fs.realpathSync(target), target, 'Symlinked request visibility module');
  assert.ok(fs.readFileSync(target).equals(reviewed), 'Request visibility module drifted');

  const engine = path.join(core, 'ltk/core/engine.lua');
  assert.equal(fs.realpathSync(engine), engine, 'Symlinked card engine');
  const anchor = '  return ret\nend\n\n--- 对那个id应用锁定视为技';
  const insert = `  -- Opaque card aliases may have a face known only for the current request.
  local request = ClientInstance and ClientInstance.card_wire_request
  local face = not ret and request and request.faces and request.faces[id]
  if face then
    request.cards = request.cards or {}
    if not request.cards[id] then
      local card = self:cloneCard(face.name, face.suit, face.number)
      card.id = id
      request.cards[id] = card
    end
    return request.cards[id]
  end
`;
  const source = fs.readFileSync(engine, 'utf8');
  if (source.includes(insert + anchor)) return;
  assert.equal(mode, '--apply', 'Request card lookup is missing');
  assert.equal(source.split(anchor).length, 2, 'Request card lookup source drift');
  fs.writeFileSync(engine, source.replace(anchor, insert + anchor));
}
