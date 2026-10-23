import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { test } from 'node:test';
import { LuaRuntime } from '../src/engine/luaRuntime';

function mountRuntimePackages(): Map<string, Uint8Array> {
  const root = path.resolve(process.cwd(), '../../runtime/packages');
  const files = new Map<string, Uint8Array>();
  function visit(dir: string): void {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.name === '.git') continue;
      const absolute = path.join(dir, entry.name);
      if (entry.isDirectory()) visit(absolute);
      else if (entry.isFile() && /\.(lua|json|md|qml|js)$/iu.test(entry.name)) {
        files.set(`packages/${path.relative(root, absolute).split(path.sep).join('/')}`,
          fs.readFileSync(absolute));
      }
    }
  }
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    if (entry.isDirectory()) visit(path.join(root, entry.name));
  }
  return files;
}

test('native SmartAI records QA-only strategy errors without misclassifying recovered PlayCard requests', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(), callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });
  await runtime.start();
  try {
    const actual = runtime.eval<{
      accepted: boolean; acceptedCounter: number; fallbackCounter: number;
      recovered: number; unrecovered: number; other: number;
      failedReply: string; failureReason: number; activeReply: string;
      activeReason: number; untraced: boolean;
    }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')
      local previousConfig = ServerConfig
      ServerConfig = { tqsQa = { enabled = true } }
      local candidateCard
      for id, card in pairs(Fk.cards) do
        if type(id) == 'number' and card.trueName == 'slash' then
          candidateCard = id
          break
        end
      end
      assert(candidateCard)
      local store = {}
      local room = {
        getTag = function(_, key) return store[key] end,
        setTag = function(_, key, value) store[key] = value end,
        request_handlers = {
          PlayCard = { new = function()
            return { setup = function() end, feasible = function() return true end,
              selected_targets = {}, pendings = {} }
          end },
          AskForUseActiveSkill = { new = function(_, _, data)
            return { skill_name = data[1], setup = function() end,
              feasible = function() return false end,
              selected_targets = {}, pendings = {} }
          end },
        },
      }
      local bot = SmartAI:new({ id = 1, hp = 4, maxHp = 4 })
      bot.room = room
      local enabled = {'hs__kurou', 'hs__zhiheng'}
      local strategies = {
        hs__kurou = {skill_name = 'hs__kurou', use_priority = 2,
          makeReply = function() return false, 200 end},
        hs__zhiheng = {skill_name = 'hs__zhiheng', use_priority = 1,
          makeReply = function() return {card = candidateCard, targets = {}}, 50 end},
      }
      bot.getEnabledSkills = function() return enabled end
      bot.getEnabledCards = function() return {} end
      bot.findStrategyOfSkill = function(_, _, name) return strategies[name] end
      bot.selectSkill = function() end
      bot.unSelectAll = function() end
      bot.currentSkill = function() return nil end

      bot.command, bot.data = 'PlayCard', nil
      local acceptedReply = bot:makeReply()
      local counts = bot:getResponseMetrics()
      local acceptedCounter = counts.by_command.PlayCard.total - counts.by_command.PlayCard.fallback
      local fallbackCounter = counts.by_command.PlayCard.fallback

      enabled = {'hs__kurou'}
      bot.command, bot.data = 'PlayCard', nil
      local failedReply = bot:makeReply()
      counts = bot:getResponseMetrics()

      strategies.hs__kurou = nil
      strategies.private_dynamic_skill_name = { skill_name = 'private_dynamic_skill_name',
        use_priority = 1, makeReply = function() return true, 200 end }
      enabled = {'private_dynamic_skill_name'}
      bot.command, bot.data = 'PlayCard', nil
      bot:makeReply()

      strategies.hs__zhiheng = { skill_name = 'hs__zhiheng', use_priority = 1,
        makeReply = function() return {
          card = {skill = 'hs__zhiheng', subcards = {candidateCard}}, targets = {}
        }, 50 end }
      enabled = {'hs__zhiheng'}
      bot.command, bot.data = 'AskForUseActiveSkill', {'hs__zhiheng', 'QA', true, {}}
      local activeReply = bot:makeReply()

      local reasons = room:getTag('__tqs_prompt4_request_reasons') or {}
      local issues = room:getTag('__tqs_prompt4_strategy_issues') or {}
      local activeReason = (reasons.hs__zhiheng or {})[
        'AskForUseActiveSkill/illegal_reply/feasibility_rejected'] or 0
      local failedReason = (reasons.hs__kurou or {})[
        'PlayCard/invalid_strategy_reply/none'] or 0
      local oldTotal = issues.hs__kurou.total
      ServerConfig = { tqsQa = { enabled = false } }
      enabled = {'hs__kurou'}
      bot.command, bot.data = 'PlayCard', nil
      bot:makeReply()
      local untraced = (room:getTag('__tqs_prompt4_strategy_issues') or {}).hs__kurou.total == oldTotal
      ServerConfig = previousConfig
      return {
        accepted = type(acceptedReply) == 'table',
        acceptedCounter = acceptedCounter, fallbackCounter = fallbackCounter,
        recovered = issues.hs__kurou.recovered,
        unrecovered = issues.hs__kurou.unrecovered,
        other = issues.other.total,
        failedReply = failedReply, failureReason = failedReason,
        activeReply = activeReply, activeReason = activeReason,
        untraced = untraced,
      }
    `);
    assert.deepEqual(actual, {
      accepted: true, acceptedCounter: 1, fallbackCounter: 0,
      recovered: 1, unrecovered: 1, other: 1,
      failedReply: '__cancel', failureReason: 1,
      activeReply: '__cancel', activeReason: 1, untraced: true,
    });
  } finally {
    runtime.close();
  }
});
