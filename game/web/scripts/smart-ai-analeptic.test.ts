import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { LuaRuntime } from '../src/engine/luaRuntime';

const PACKAGE_FILE = /\.(lua|json|md|qml|js)$/iu;

function mountRuntimePackages(): Map<string, Uint8Array> {
  const root = path.resolve(process.cwd(), '../../runtime/packages');
  const files = new Map<string, Uint8Array>();
  function visit(directory: string): void {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      if (entry.name === '.git') continue;
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(absolute);
      else if (entry.isFile() && PACKAGE_FILE.test(entry.name)) {
        const relative = path.relative(root, absolute).split(path.sep).join('/');
        files.set(`packages/${relative}`, fs.readFileSync(absolute));
      }
    }
  }
  visit(root);
  return files;
}

test('Tửu requires a legal, beneficial Sát follow-up and predicts its damage bonus', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, setup() {}, ui() {}, log() {} },
  });
  await runtime.start();
  try {
    const result = runtime.eval<{
      noSlash: boolean;
      noTarget: boolean;
      hostileAlly: boolean;
      negligibleAttack: boolean;
      alreadyDrank: boolean;
      combo: boolean;
      elementalCombo: boolean;
      selectionReset: boolean;
      emergencyRecover: boolean;
      bonusApplied: boolean;
      slashDamage: number[];
    }>(`
      local previousCreateSkill = fk.CreateSkill
      local strategyClass = {
        think = function(self, ai)
          ai.baseThinkCalls = ai.baseThinkCalls + 1
          return { 100, {} }, ai.mem.analeptic_followup_bonus or 0
        end,
      }
      Fk.Ltk = { AI = {
        CardSkillStrategy = strategyClass,
        newCardSkillStrategy = function(spec)
          spec.onEffect = spec.on_effect
          return setmetatable(spec, { __index = strategyClass })
        end,
      } }
      fk.CreateSkill = function(spec)
        spec.addEffect = function() end
        spec.addAI = function(self, strategy) self.strategy = strategy end
        return spec
      end
      local cards = {
        [100] = { trueName = 'analeptic', skill = { name = 'analeptic_skill' } },
        [200] = { trueName = 'slash', skill = { name = 'slash_skill' } },
        [201] = { trueName = 'slash', skill = { name = 'fire__slash_skill' } },
      }
      Fk.getCardById = function(_, id) return cards[id] end
      local analeptic = dofile('packages/freekill-core/maneuvering/pkg/skills/analeptic.lua')
      local standard = dofile('packages/freekill-core/standard_cards/pkg/skills/slash.lua')
      local fire = dofile('packages/freekill-core/maneuvering/pkg/skills/fire__slash.lua')
      local thunder = dofile('packages/freekill-core/maneuvering/pkg/skills/thunder__slash.lua')

      local ai = {
        command = 'PlayCard', player = { drank = 0 }, mem = {},
        cards = {100}, baseThinkCalls = 0, selected = nil,
        targets = {}, benefit = 0, cleared = 0,
      }
      function ai:getEnabledCards() return self.cards end
      function ai:selectCard(id, value) self.selected = value and id or nil end
      function ai:unSelectAll() self.selected = nil; self.cleared = self.cleared + 1 end
      function ai:findStrategyOfSkill(_, skillName)
        if skillName ~= 'slash_skill' and skillName ~= 'fire__slash_skill' then return nil end
        return { chooseTargets = function()
          assert(self.selected ~= nil)
          return self.targets, self.benefit
        end }
      end
      local strategy = analeptic.strategy
      local function rejected()
        ai.mem = {}
        local decision, value = strategy:think(ai)
        return decision == nil and value < 0
      end
      local noSlash = rejected()
      ai.cards = {100, 200}
      local noTarget = rejected()
      ai.targets = {{id = 18}}
      ai.benefit = -200
      local hostileAlly = rejected()
      ai.benefit = 0.25
      local negligibleAttack = rejected()
      ai.benefit = 200
      ai.player.drank = 1
      local alreadyDrank = rejected()
      ai.player.drank = 0
      ai.mem = {}
      local decision, value = strategy:think(ai)
      local combo = decision and decision[1] == 100 and value == 280
      local selectionReset = ai.selected == nil and ai.cleared > 0
      local logic = { ai = ai, benefit = 0 }
      strategy:onEffect(logic, {extra_data = {}})
      local bonusApplied = logic.benefit == 280
      ai.cards = {100, 201}
      ai.mem = {}
      local second, secondValue = strategy:think(ai)
      local elementalCombo = second and second[1] == 100 and secondValue == 280

      ai.command = 'AskForUseCard'
      ai.cards = {100}
      ai.mem = {}
      local rescue, rescueValue = strategy:think(ai)
      local recovered = false
      strategy:onEffect({recover = function() recovered = true end}, {
        extra_data = {analepticRecover = true}, to = ai.player,
      })
      local emergencyRecover = rescue ~= nil and rescueValue == 0 and recovered

      local slashDamage = {}
      for _, skill in ipairs({standard, fire, thunder}) do
        local attacker = { drank = 2 }
        local simulation = {
          ai = { player = attacker },
          damage = function(_, spec) return table.insert(slashDamage, spec.damage) end,
        }
        skill.strategy:onEffect(simulation, { from = attacker, to = {id = 18} })
      end
      fk.CreateSkill = previousCreateSkill
      return {
        noSlash = noSlash, noTarget = noTarget,
        hostileAlly = hostileAlly, negligibleAttack = negligibleAttack,
        alreadyDrank = alreadyDrank, combo = combo,
        elementalCombo = elementalCombo, selectionReset = selectionReset,
        emergencyRecover = emergencyRecover, bonusApplied = bonusApplied,
        slashDamage = slashDamage,
      }
    `);
    for (const [name, passed] of Object.entries(result)) {
      if (name !== 'slashDamage') assert.equal(passed, true, name);
    }
    assert.deepEqual(result.slashDamage, [3, 3, 3]);
  } finally {
    runtime.close();
  }
});

test('SmartAI PlayCard chooses Tửu then Sát across consecutive legal decisions', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, setup() {}, ui() {}, log() {} },
  });
  await runtime.start();
  try {
    const outcome = runtime.eval<{
      first: number;
      second: number;
      noTarget: boolean;
      noSlash: boolean;
      cleanSelection: boolean;
    }>(`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')

      local originalCreateSkill = fk.CreateSkill
      local originalGetCard = Fk.getCardById
      fk.CreateSkill = function(spec)
        spec.addEffect = function() end
        spec.addAI = function(self, strategy)
          strategy.skill_name = self.name
          self.strategy = strategy
        end
        return spec
      end

      local cards = {
        [100] = { id = 100, trueName = 'analeptic', skill = { name = 'analeptic_skill' } },
        [200] = { id = 200, trueName = 'slash', skill = { name = 'slash_skill' } },
      }
      Fk.getCardById = function(_, id) return cards[id] end
      local wine = dofile('packages/freekill-core/maneuvering/pkg/skills/analeptic.lua')
      local slash = Fk.Ltk.AI.newCardSkillStrategy {}
      slash.skill_name = 'slash_skill'

      local attacker = { drank = 0 }
      local ai = SmartAI:new(attacker)
      ai.command = 'PlayCard'
      ai.handler = {}
      ai.mem = {}
      ai.selected = nil
      ai.hasSlash = true
      ai.hasTarget = true
      ai.getEnabledSkills = function() return {} end
      function ai:getEnabledCards()
        local ids = { 100 }
        if self.hasSlash then table.insert(ids, 200) end
        return table.filter(ids, function(id) return id ~= self.selected end)
      end
      function ai:selectCard(id, enabled)
        assert(cards[id] and (not enabled or self.selected == nil))
        self.selected = enabled and id or nil
      end
      function ai:getSelectedCard()
        return cards[self.selected]
      end
      function ai:unSelectAll() self.selected = nil end
      function ai:selectSkill() end
      function ai:findStrategyOfSkill(_, skillName)
        if skillName == 'analeptic_skill' then return wine.strategy end
        if skillName == 'slash_skill' then return slash end
      end
      function wine.strategy:chooseTargets(smart)
        assert(smart.selected == 100)
        return {}, smart.mem.analeptic_followup_bonus or 0
      end
      function slash:chooseTargets(smart)
        assert(smart.selected == 200)
        if not smart.hasTarget then return {}, -100000 end
        return {{ id = 18 }}, smart.player.drank > 0 and 400 or 200
      end

      local firstReply = ai:handlePlayCard()
      attacker.drank = 1
      ai.mem = {}
      local secondReply = ai:handlePlayCard()
      attacker.drank = 0
      ai.hasTarget = false
      ai.mem = {}
      local noTargetReply = ai:handlePlayCard()
      ai.hasSlash = false
      ai.mem = {}
      local noSlashReply = ai:handlePlayCard()

      fk.CreateSkill = originalCreateSkill
      Fk.getCardById = originalGetCard
      return {
        first = type(firstReply) == 'table' and firstReply.card or firstReply,
        second = type(secondReply) == 'table' and secondReply.card or secondReply,
        noTarget = noTargetReply == '',
        noSlash = noSlashReply == '',
        cleanSelection = ai.selected == nil,
      }
    `);
    assert.equal(outcome.first, 100, JSON.stringify(outcome));
    assert.equal(outcome.second, 200, 'the next PlayCard decision should use Sát');
    assert.equal(outcome.noTarget, true, 'Tửu should be held when there is no legal attack target');
    assert.equal(outcome.noSlash, true, 'Tửu should be held without a playable Sát');
    assert.equal(outcome.cleanSelection, true);
  } finally {
    runtime.close();
  }
});
