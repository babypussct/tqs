import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import os from 'node:os';

const here = path.dirname(fileURLToPath(import.meta.url));
const packageDir = path.join(here, 'tqs_qa');
const nativeCatalog = JSON.parse(fs.readFileSync(path.join(packageDir, 'catalog.json'), 'utf8'));
const browserCatalogPath = path.resolve(here, '../../../game/web/scripts/real-lua-e2e/qa-scenarios.ts');
const browserCatalog = fs.readFileSync(browserCatalogPath, 'utf8');

test('native tqs_qa catalog keeps the browser scenario ids, seeds and commands in lockstep', () => {
  for (const scenario of nativeCatalog.scenarios) {
    const key = scenario.id.includes('-') ? `'${scenario.id}'` : scenario.id;
    const match = browserCatalog.match(new RegExp(`${key.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\$&')}: \\{([\\s\\S]*?)\\n  \\},`));
    assert.ok(match, `browser QA catalog is missing ${scenario.id}`);
    const seed = match[1].match(/seed: (0x[0-9a-f]+)/u)?.[1];
    const expectedCommand = match[1].match(/expectedCommand: '([^']+)'/u)?.[1];
    assert.equal(Number(seed), scenario.seed, `${scenario.id} seed drift`);
    assert.equal(expectedCommand, scenario.expectedCommand, `${scenario.id} expected command drift`);
  }
});

test('fazheng-enyuan locks three real Slashes, Longdan conversions and optional reactions', () => {
  const scenario = nativeCatalog.scenarios.find(({ id }) => id === 'fazheng-enyuan');
  assert.ok(scenario, 'fazheng-enyuan catalog entry is required');
  assert.equal(scenario.playerCount, 2);
  assert.deepEqual(scenario.players, {
    actor: { general: 'hs__guojia', deputy: 'hs__simayi', kingdom: 'wei' },
    target: { general: 'hs__zhaoyun', deputy: 'ld__fazheng', kingdom: 'shu' },
  });
  assert.deepEqual(scenario.attackSteps.map(({ from, to, amount, mandatorySkills, optionalSkills }) => ({
    from, to, amount, mandatorySkills, optionalSkills,
  })), [
    { from: 'actor', to: 'target', amount: 0, mandatorySkills: [], optionalSkills: [] },
    { from: 'actor', to: 'target', amount: 1, mandatorySkills: ['ld__enyuan'], optionalSkills: [] },
    { from: 'actor', to: 'target', amount: 1, mandatorySkills: ['ld__enyuan'], optionalSkills: [] },
    { from: 'target', to: 'actor', amount: 1, mandatorySkills: [], optionalSkills: ['hs__yiji', 'fankui'] },
  ]);
  assert.deepEqual(scenario.attackSteps[3].expectedInvokedSkills, ['hs__yiji', 'fankui']);
  assert.equal(scenario.cards.filter((card) => card.owner === 'actor' && card.match.trueName === 'slash').length, 3);
  assert.deepEqual(scenario.cards.filter((card) => card.owner === 'target').map((card) => card.match.trueName),
    ['slash', 'jink', 'peach']);
});

// Execute the package's actual startup validation/registration in Lua. JSON
// decoding and engine registration are stubs; this is not C++ gameplay proof.
function luaValue(value) {
  if (Array.isArray(value)) return `{${value.map(luaValue).join(',')}}`;
  if (value && typeof value === 'object') return `{${Object.entries(value)
    .map(([key, item]) => `[${JSON.stringify(key)}]=${luaValue(item)}`).join(',')}}`;
  if (value === null) return 'nil';
  return JSON.stringify(value);
}

function loadNativeCatalog(catalog) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'tqs-qa-load-'));
  try {
    const manifest = { schemaVersion: 1, package: 'tqs_qa', status: 'verified',
      sourceRevision: 'fixture', catalogSha256: 'fixture', packageSha256: 'fixture' };
    const dir = path.join(root, 'packages/tqs_qa');
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, 'package.manifest.json'), JSON.stringify(manifest));
    fs.writeFileSync(path.join(dir, 'catalog.json'), JSON.stringify(catalog));
    fs.writeFileSync(path.join(root, 'load.lua'), `
      ServerConfig = {tqsQa={enabled=true,allowedUsers={'qa-fixture'}}}
      function table.contains(items, value)
        for _, item in ipairs(items) do if item == value then return true end end
        return false
      end
      local decoded = {${luaValue(manifest)}, ${luaValue(catalog)}}
      local index = 0
      json = {decode=function() index = index + 1; return decoded[index] end}
      local registered
      Package = {SpecialPack=1, new=function() return {
        loadSkillSkels=function(self, skills)
          assert(#skills == 1 and #skills[1].effects >= 8, 'missing director effects')
          registered = skills[1]
        end
      } end}
      fk = setmetatable({CreateSkill=function(spec)
        spec.effects = {}
        function spec:addEffect(event, effect) table.insert(self.effects, {event, effect}) end
        return spec
      end}, {__index=function(_, key) return key end})
      local extension = dofile(arg[1])
      assert(extension and extension.extensionName == 'tqs_qa')
      for _, event in ipairs({fk.DrawInitialCards, fk.GameStart, fk.RoundStart, fk.GameFinished}) do
        local automatic
        for _, entry in ipairs(registered.effects) do if entry[1] == event then automatic = entry[2] end end
        assert(automatic and type(automatic.on_trigger) == 'function' and automatic.on_use == nil,
          'QA lifecycle must execute directly without asking to invoke the director')
      end
      local room = {players={}}
      function room:getSettings(key) return key == 'roomName' and 'TQSQA/fazheng-enyuan/0x6e9a2026' end
      function room:getTag() return nil end
      local p = {id=1, room=room, _splayer={getScreenName=function() return 'not-allowlisted' end}}
      room.players = {p, {id=2, room=room}}
      local prepared
      for _, entry in ipairs(registered.effects) do if entry[1] == fk.GamePrepared then prepared = entry[2] end end
      local ok, err = pcall(function() prepared.on_trigger(nil, nil, nil, p, {}) end)
      assert(not ok and tostring(err):find('non%-allowlisted player'),
        'GamePrepared must read the native _splayer name and enforce the allowlist')
      print('native catalog startup fixture PASS')
    `);
    return execFileSync('lua', [path.join(root, 'load.lua'), path.join(packageDir, 'init.lua')],
      { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

test('actual Lua startup accepts four Slash steps and rejects the old two-damage or compulsory-Yiji contract', () => {
  assert.match(loadNativeCatalog(nativeCatalog), /startup fixture PASS/);
  const old = structuredClone(nativeCatalog);
  old.scenarios.find(({ id }) => id === 'fazheng-enyuan').attackSteps.length = 2;
  assert.throws(() => loadNativeCatalog(old), /four Slash steps/);
  const compulsory = structuredClone(nativeCatalog);
  compulsory.scenarios.find(({ id }) => id === 'fazheng-enyuan').attackSteps[3].mandatorySkills = ['hs__yiji'];
  assert.throws(() => loadNativeCatalog(compulsory), /must remain optional/);
});
