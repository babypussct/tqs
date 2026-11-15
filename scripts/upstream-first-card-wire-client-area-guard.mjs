// Install the reviewed ChangeCardArea client projection in the isolated
// candidate only. The negotiated card-wire protocol remains disabled.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [mode, input] = process.argv.slice(2);
assert.ok(['--apply', '--check'].includes(mode) && input,
  'expected --apply|--check <isolated-candidate-core>');
const root = fs.realpathSync(input);
assert.match(root, /\/scratch\/evidence\/[^/]+\/candidate-runtime\/packages\/freekill-core$/u,
  'client area guard restricted to isolated candidate');
const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const clientDir = path.join(root, 'ltk/client');
assert.equal(fs.realpathSync(clientDir), clientDir, 'client directory must not be a symlink');

const modulePath = path.join(clientDir, 'card_wire_area.lua');
const expectedModule = fs.readFileSync(path.join(repo,
  'deploy/freekill-native/qa/card-wire-client-area.lua'), 'utf8');
if (fs.existsSync(modulePath)) {
  assert.equal(fs.realpathSync(modulePath), modulePath, 'area module must not be a symlink');
  assert.equal(fs.readFileSync(modulePath, 'utf8'), expectedModule,
    'installed ChangeCardArea client module differs from reviewed source');
} else {
  assert.equal(mode, '--apply', 'candidate ChangeCardArea client module missing');
  fs.writeFileSync(modulePath, expectedModule);
}

const clientPath = path.join(clientDir, 'client.lua');
assert.equal(fs.realpathSync(clientPath), clientPath, 'client must not be a symlink');
let client = fs.readFileSync(clientPath, 'utf8');
const callback = '  self:addCallback("ChangeCardArea", self.handleChangeCardArea)';
if (!client.includes(callback)) {
  assert.equal(mode, '--apply', 'candidate ChangeCardArea callback registration missing');
  const anchor = '  self:addCallback("SetPlayerPile", self.setPlayerPile)';
  assert.equal(client.split(anchor).length, 2, 'client callback anchor drifted');
  client = client.replace(anchor, `${callback}\n${anchor}`);
}

const legacy = `function Client:handleChangeCardArea(data)
  local cards, area, areaCards = table.unpack(data)
  self:changeCardArea(cards, area, areaCards)
end
`;
const projected = `function Client:handleChangeCardArea(data)
  if self.card_wire_version == 1 or (type(data) == "table" and data.count ~= nil) then
    return require("ltk.client.card_wire_area").receive(self, data)
  end
  local cards, area, areaCards = table.unpack(data)
  self:changeCardArea(cards, area, areaCards)
end
`;
if (!client.includes(projected)) {
  assert.equal(mode, '--apply', 'candidate ChangeCardArea callback is not guarded');
  assert.equal(client.split(legacy).length, 2, 'ChangeCardArea callback source drifted');
  client = client.replace(legacy, projected);
}
if (mode === '--apply') fs.writeFileSync(clientPath, client);
assert.match(client, /self:addCallback\("ChangeCardArea", self\.handleChangeCardArea\)/u);
assert.match(client, /require\("ltk\.client\.card_wire_area"\)\.receive\(self, data\)/u);
assert.match(client, /self:changeCardArea\(cards, area, areaCards\)/u);
console.log(`PASS isolated count-only ChangeCardArea client ${mode}; v1 remains disabled`);
