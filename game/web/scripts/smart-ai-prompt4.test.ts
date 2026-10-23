import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { runPrompt4Audit } from './smart-ai-prompt4-audit';
import { loadUpstreamFiles, UPSTREAM_PACKAGE_NAMES } from './upstream-packages';

const PACKAGE_FILE = /\.(lua|json|md|qml|js)$/iu;

function mountRuntimePackages(): Map<string, Uint8Array> {
  const packagesRoot = path.resolve(process.cwd(), '../../runtime/packages');
  const files = new Map<string, Uint8Array>();
  function visit(directory: string) {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      if (entry.name === '.git') continue;
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(absolute);
      else if (entry.isFile() && PACKAGE_FILE.test(entry.name)) {
        files.set(`packages/${path.relative(packagesRoot, absolute).split(path.sep).join('/')}`,
          fs.readFileSync(absolute));
      }
    }
  }
  for (const entry of fs.readdirSync(packagesRoot, { withFileTypes: true })) {
    if (entry.isDirectory()) visit(path.join(packagesRoot, entry.name));
  }
  return files;
}

test('Prompt 4 inventory uses the real new_heg_mode pool and records pool-vs-match frequency', async () => {
  const baseline = await runPrompt4Audit(loadUpstreamFiles(
    path.resolve(process.cwd(), '../../scratch/upstream'), UPSTREAM_PACKAGE_NAMES,
  ));
  const report = await runPrompt4Audit();
  assert.equal(baseline.pass, true, baseline.failures.join('; '));
  assert.equal(report.pass, true, report.failures.join('; '));
  assert.ok(report.eligibleGeneralCount >= 300);
  assert.equal(report.poolSkillReferenceCount, 528);
  assert.equal(report.poolUniqueSkillCount, 520);
  assert.equal(report.frequencyEvidence.observedMatches.skillActivationCountsAvailable, false);
  assert.equal(report.frequencyEvidence.observedMatches.samples, 0);
  assert.equal(report.backlog.length, report.defaultHandlerSkillCount);
  assert.equal(report.backlog.length, 101);
  assert.deepEqual(report.backlog.map((row) => row.order),
    Array.from({ length: report.backlog.length }, (_, index) => index + 1));
  assert.equal(report.backlog[0]?.id, 'duanxie');
  assert.ok(report.backlog.every((row) => row.observedMatchFrequency === null));

  const group = report.priority.filter((row) => row.status === 'group_1');
  assert.equal(group.length, 6);
  for (const id of ['shangyi', 'tianyi', 'tiaoxin', 'hs__zhiheng', 'hs__kurou', 'hs__qiangxi']) {
    const baselineSkill = baseline.skills.find((item) => item.id === id);
    const row = report.priority.find((item) => item.id === id);
    assert.equal(baselineSkill?.handlerKind, 'default_handler', `${id} must be default in baseline`);
    assert.ok(row, `missing priority row for ${id}`);
    assert.equal(row.baselineHandlerKind, 'default_handler');
    assert.equal(row.candidateHandlerKind, 'ai_handler');
    assert.equal(row.observedMatchFrequency, null);
    assert.ok(row.priority > 0);
  }
  const group2 = report.priority.filter((row) => row.status === 'group_2');
  assert.equal(group2.length, 6);
  for (const id of ['hs__longdan', 'hs__luanji', 'hs__wusheng', 'huoji', 'jijiu', 'kanpo']) {
    const baselineSkill = baseline.skills.find((item) => item.id === id);
    const row = report.priority.find((item) => item.id === id);
    assert.equal(baselineSkill?.handlerKind, 'default_handler', `${id} must be default in baseline`);
    assert.ok(row, `missing priority row for ${id}`);
    assert.equal(row.status, 'group_2');
    assert.equal(row.baselineHandlerKind, 'default_handler');
    assert.equal(row.candidateHandlerKind, 'ai_handler');
    assert.equal(row.observedMatchFrequency, null);
  }
  const group3 = report.priority.filter((row) => row.status === 'group_3');
  assert.equal(group3.length, 6);
  for (const id of ['aocai', 'beizhu', 'dimeng', 'choufa', 'cunsi', 'duanfa']) {
    const baselineSkill = baseline.skills.find((item) => item.id === id);
    const row = report.priority.find((item) => item.id === id);
    assert.equal(baselineSkill?.handlerKind, 'default_handler', `${id} must be default in baseline`);
    assert.ok(row, `missing priority row for ${id}`);
    assert.equal(row.status, 'group_3');
    assert.equal(row.baselineHandlerKind, 'default_handler');
    assert.equal(row.candidateHandlerKind, 'ai_handler');
    assert.equal(row.observedMatchFrequency, null);
  }
});

test('Prompt 4 native baseline switch is opt-in and hides only the selected strategies', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });
  await runtime.start();
  try {
    const output = runtime.eval<{ candidate: boolean; baseline: boolean; restored: boolean }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')

      local bot = SmartAI:new({ id = 1, hp = 3, maxHp = 4, kingdom = 'wei' })
      local active = Fk.Ltk.AI.ActiveStrategy
      local oldConfig = ServerConfig
      ServerConfig = {}
      local candidate = bot:findStrategyOfSkill(active, 'hs__wusheng') ~= nil
      ServerConfig = { tqsPrompt4Baseline = true }
      local baseline = bot:findStrategyOfSkill(active, 'hs__wusheng') == nil
      local unrelated = bot:findStrategyOfSkill(active, 'zhiheng') ~= nil
      ServerConfig = oldConfig
      local restored = bot:findStrategyOfSkill(active, 'hs__wusheng') ~= nil
      return { candidate = candidate, baseline = baseline and unrelated, restored = restored }
    `);
    assert.deepEqual(output, { candidate: true, baseline: true, restored: true });
  } finally {
    runtime.close();
  }
});

test('Prompt 4 group 1 selects legal resources and faction-aware targets against the no-strategy baseline', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });
  await runtime.start();
  try {
    const output = runtime.eval<{
      registered: Record<string, boolean>;
      candidateHasStrategies: boolean;
      lowId: number;
      highId: number;
      weaponId: number;
      zhiheng: { cards: number[]; targets: number[]; value: number };
      kurou: { cards: number[]; targets: number[]; value: number };
      qiangxi: { cards: number[]; targets: number[]; value: number };
      tiaoxin: { cards: number[]; targets: number[]; value: number };
      tianyi: { cards: number[]; targets: number[]; value: number };
      shangyi: { cards: number[]; targets: number[]; value: number };
      shangyiChoice: string;
      shangyiDiscard: { cards: number[]; choice: string };
      pindian: { card: { subcards: number[] }; targets: number[] };
      pindianRequest: { card: { subcards: number[] }; targets: number[] };
    }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')

      local function findCard(predicate)
        for id, card in pairs(Fk.cards) do
          if type(id) == 'number' and predicate(card) then return id end
        end
      end
      local slash = findCard(function(card) return card.trueName == 'slash' end)
      local weapon = findCard(function(card) return card.sub_type == Card.SubtypeWeapon end)
      local high = findCard(function(card) return type(card.number) == 'number' and card.number >= 13 end)
      local low = findCard(function(card) return type(card.number) == 'number' and card.number <= 2 end)
      assert(slash and weapon and high and low)

      local me = { id = 1, hp = 3, maxHp = 4, kingdom = 'wei' }
      function me:getCardIds(area)
        if area == 'h' then return { slash, high, low } end
        return { weapon }
      end
      function me:prohibitDiscard() return false end
      function me:isKongcheng() return false end

      local enemy = { id = 2, kingdom = 'shu', hand = 4 }
      function enemy:getHandcardNum() return self.hand end
      function enemy:isKongcheng() return self.hand == 0 end
      local smallerEnemy = { id = 3, kingdom = 'shu', hand = 1 }
      function smallerEnemy:getHandcardNum() return self.hand end
      function smallerEnemy:isKongcheng() return self.hand == 0 end
      local ally = { id = 4, kingdom = 'wei', hand = 5 }
      function ally:getHandcardNum() return self.hand end

      local values = {[low] = 1, [high] = 7, [slash] = 5, [weapon] = 2}
      local function relation(target)
        if target == ally then
          return {state = 'friend', confidence = 1, attitude = 1}
        end
        return {state = 'enemy', confidence = 1, attitude = -1}
      end
      local function fakeAi(enabledCards, enabledTargets)
        local ai = { player = me, data = nil }
        function ai:getEnabledCards() return enabledCards end
        function ai:getEnabledTargets() return enabledTargets end
        function ai:getCardValue(id) return values[id] or 0 end
        function ai:getFactionRelation(target) return relation(target) end
        function ai:getBenefitOfEvents(callback)
          local logic = { score = 0 }
          function logic:throwCard(cards) for _, id in ipairs(cards) do self.score = self.score - (values[id] or 0) end end
          function logic:drawCards(_, count) self.score = self.score + count * 25 end
          function logic:loseHp(_, count) self.score = self.score - count * 100 end
          function logic:damage(data) self.score = self.score + (data.to == me and -200 or 200) end
          callback(logic)
          return logic.score
        end
        return ai
      end
      local function strategy(name, kind)
        local skill = Fk.skills[name]
        assert(skill, name .. ' missing from active pool')
        local list = skill:getSkeleton().ai_strategies[kind]
        assert(list and #list > 0, name .. ' has no candidate AI handler')
        return list[#list]
      end
      local active = Fk.Ltk.AI.ActiveStrategy
      local choice = Fk.Ltk.AI.ChoiceStrategy
      local registered = {}
      for _, name in ipairs({'shangyi', 'tianyi', 'tiaoxin', 'hs__zhiheng', 'hs__kurou', 'hs__qiangxi'}) do
        registered[name] = #(Fk.skills[name]:getSkeleton().ai_strategies[active] or {}) > 0
      end

      local function normalize(result, value)
        return {cards = result and result[1] or {}, targets = result and table.map(result[2] or {}, Util.IdMapper) or {}, value = value or -100000}
      end
      local zret, zv = strategy('hs__zhiheng', active):think(fakeAi({low, high}, {}))
      local kret, kv = strategy('hs__kurou', active):think(fakeAi({low, high}, {}))
      local qret, qv = strategy('hs__qiangxi', active):think(fakeAi({weapon}, {ally, enemy}))
      local tret, tv = strategy('tiaoxin', active):think(fakeAi({}, {ally, enemy, smallerEnemy}))
      local aret, av = strategy('tianyi', active):think(fakeAi({}, {enemy, smallerEnemy}))
      local sret, sv = strategy('shangyi', active):think(fakeAi({}, {ally, enemy, smallerEnemy}))

      local choiceAi = fakeAi({}, {})
      choiceAi.data = {{'shangyi_card', 'shangyi_hidden'}, {'shangyi_card', 'shangyi_hidden'}, {1, 1}, false, 'shangyi', '', false, true}
      local shangyiChoice = strategy('shangyi', choice):think(choiceAi)

      local bot = SmartAI:new(me)
      bot.getCardValue = function(_, id) return values[id] or 0 end
      local shangyiDiscard = bot:handleAskForCardsAndChoice({
        cards = {low, high}, choices = {'OK'}, disabled = {}, min = 0, max = 1,
        prompt = '#shangyi_card:2',
      })

      local selectedPindian
      bot.handler = { skill_name = 'choose_cards_skill' }
      bot.data = {'choose_cards_skill', '#askForPindian:::tianyi', false, {}}
      bot.getEnabledCards = function() return { low, high } end
      bot.selectCard = function(_, id) selectedPindian = id end
      bot.doOKButton = function() return {card = {subcards = {selectedPindian}}, targets = {}} end
      local pindian = bot:handleAskForUseActiveSkill()

      local requestBot = SmartAI:new(me)
      local PindianHandler = {}
      function PindianHandler:new(_, data)
        return {skill_name = data[1], setup = function() end, feasible = function() return true end}
      end
      requestBot.room = {request_handlers = {AskForUseActiveSkill = PindianHandler}}
      requestBot.command = 'AskForUseActiveSkill'
      requestBot.data = {'choose_cards_skill', '#askForPindian:::tianyi', false, {}}
      requestBot.getEnabledCards = function() return {low, high} end
      requestBot.selectCard = function(_, id) selectedPindian = id end
      requestBot.doOKButton = function(self)
        local reply = {card = {subcards = {selectedPindian}}, targets = {}}
        self._last_ai_reply = reply
        return reply
      end
      local pindianRequest = requestBot:makeReply()

      return {
        registered = registered,
        candidateHasStrategies = registered.shangyi and registered.tianyi and registered.tiaoxin and
          registered.hs__zhiheng and registered.hs__kurou and registered.hs__qiangxi,
        lowId = low,
        highId = high,
        weaponId = weapon,
        zhiheng = normalize(zret, zv),
        kurou = normalize(kret, kv),
        qiangxi = normalize(qret, qv),
        tiaoxin = normalize(tret, tv),
        tianyi = normalize(aret, av),
        shangyi = normalize(sret, sv),
        shangyiChoice = shangyiChoice,
        shangyiDiscard = shangyiDiscard,
        pindian = pindian,
        pindianRequest = pindianRequest,
      }
    `);

    for (const [name, registered] of Object.entries(output.registered)) {
      assert.equal(registered, true, `${name} must be registered in candidate AI`);
    }
    assert.equal(output.candidateHasStrategies, true);
    assert.equal(output.zhiheng.cards[0], output.lowId, JSON.stringify(output));
    assert.ok(output.zhiheng.cards.length >= 1 && output.zhiheng.value > 0);
    assert.equal(output.kurou.cards.length, 1);
    assert.ok(output.kurou.value > 0);
    assert.deepEqual(output.qiangxi.targets, [2]);
    assert.equal(output.qiangxi.cards[0], output.weaponId);
    assert.ok(output.qiangxi.value > 0);
    assert.deepEqual(output.tiaoxin.targets, [2], JSON.stringify(output));
    assert.deepEqual(output.tianyi.targets, [3], JSON.stringify(output));
    assert.deepEqual(output.shangyi.targets, [2], JSON.stringify(output));
    assert.equal(output.shangyiChoice, 'shangyi_card');
    assert.equal(output.shangyiDiscard.choice, 'OK');
    assert.equal(output.shangyiDiscard.cards.length, 1);
    assert.deepEqual(output.pindian.targets, []);
    assert.equal(output.pindian.card.subcards[0], output.highId);
    assert.deepEqual(output.pindianRequest.targets, []);
    assert.equal(output.pindianRequest.card.subcards[0], output.highId);
  } finally {
    runtime.close();
  }
});

test('Prompt 4 group 2 converts legal cards, preserves response context, and beats the raw-card baseline', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });
  await runtime.start();
  try {
    const output = runtime.eval<{
      registered: Record<string, boolean>;
      longdanResponse: { card: { subcards: number[] }; targets: number[]; value: number };
      longdanUse: { card: { subcards: number[] }; targets: number[]; value: number };
      luanji: { card: { subcards: number[] }; targets: number[]; value: number };
      wusheng: { card: { subcards: number[] }; targets: number[]; value: number };
      huoji: { card: { subcards: number[] }; targets: number[]; value: number };
      jijiu: { card: { subcards: number[] }; targets: number[]; value: number };
      kanpo: { card: { subcards: number[] }; targets: number[]; value: number };
      dispatcherResponse: { card: { skill: string; subcards: number[] }; targets: number[] };
      dispatcherJijiu: { card: { skill: string; subcards: number[] }; targets: number[] };
      baselineResponse: { card: number; targets: number[] };
      ids: Record<string, number>;
    }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')
      Fk.filtered_cards = Fk.filtered_cards or {}
      Fk.printed_cards = Fk.printed_cards or {}

      local function findCards(predicate)
        local ids = {}
        for id, card in pairs(Fk.cards) do
          if type(id) == 'number' and predicate(card) then table.insert(ids, id) end
        end
        table.sort(ids)
        return ids
      end
      local function findCard(predicate)
        return findCards(predicate)[1]
      end

      local jinks = findCards(function(card) return card.trueName == 'jink' end)
      local reds = findCards(function(card)
        return card.color == Card.Red and card.type ~= Card.TypeEquip
      end)
      local blacks = findCards(function(card)
        return card.color == Card.Black and card.type ~= Card.TypeEquip
      end)
      assert(#jinks >= 2 and #reds >= 2 and #blacks >= 1)

      local pair_a, pair_b, huoji_source, huoji_follow
      for _, id in ipairs(reds) do
        local card = Fk:getCardById(id)
        local suit = card:getSuitString(true)
        if not huoji_source then
          for _, other_id in ipairs(reds) do
            if other_id ~= id and Fk:getCardById(other_id):getSuitString(true) == suit then
              huoji_source, huoji_follow = id, other_id
              break
            end
          end
        end
      end
      for id, card in pairs(Fk.cards) do
        if type(id) == 'number' and card:getSuitString(true) ~= 'log_nosuit' then
          if not pair_a then
            pair_a = id
          elseif card:getSuitString(true) ~= Fk:getCardById(pair_a):getSuitString(true) then
            pair_b = id
            break
          end
        end
      end
      assert(huoji_source and huoji_follow and pair_a and pair_b)

      local red_candidates = {}
      for _, id in ipairs(reds) do
        if id ~= huoji_source and id ~= huoji_follow then table.insert(red_candidates, id) end
      end
      assert(#red_candidates >= 2)
      local jink_high, jink_low = jinks[1], jinks[2]
      local red_high, red_low = red_candidates[1], red_candidates[2]
      local black = blacks[1]
      local effect_card = findCard(function(card) return card.trueName == 'duel' end)
      assert(effect_card)

      local me = { id = 1, hp = 3, maxHp = 4, kingdom = 'wei', phase = Player.Play }
      local enemy = { id = 2, hp = 3, maxHp = 4, kingdom = 'shu', hand = 4, dead = false }
      local ally = { id = 3, hp = 2, maxHp = 4, kingdom = 'wei', hand = 4, dead = false }
      local wounded = { id = 4, hp = 2, maxHp = 4, kingdom = 'wei', hand = 2, dead = false }
      local players = { me, enemy, ally, wounded }
      local room = {
        players = players,
        alive_players = players,
        status_skills = {},
        card_marks = {},
        filtered_cards = {},
        printed_cards = {},
        getPlayerById = function(_, id)
          for _, player in ipairs(players) do if player.id == id then return player end end
        end,
        tableRandomPick = function(_, list, count)
          if count then
            local ret = {}
            for i = 1, math.min(count, #list) do table.insert(ret, list[i]) end
            return ret
          end
          return list[1]
        end,
      }
      RoomInstance = room

      function me:canUse() return true end
      function me:prohibitUse() return false end
      function me:isProhibited() return false end
      function me:getTableMark() return {} end
      function me:getHandcardNum() return 4 end
      function enemy:getHandcardNum() return self.hand end
      function ally:getHandcardNum() return self.hand end
      function wounded:getHandcardNum() return self.hand end
      function enemy:isKongcheng() return self.hand == 0 end
      function ally:isKongcheng() return self.hand == 0 end
      function wounded:isKongcheng() return self.hand == 0 end
      function ally:isWounded() return self.hp < self.maxHp end
      function wounded:isWounded() return self.hp < self.maxHp end

      local values = {
        [jink_high] = 9, [jink_low] = 1,
        [red_high] = 9, [red_low] = 1,
        [huoji_source] = 1, [huoji_follow] = 1, [pair_a] = 1, [pair_b] = 1,
        [black] = 1,
      }
      values[red_high], values[red_low] = 9, 1
      local function relation(target)
        if target == ally or target == wounded then
          return { state = 'friend', confidence = 1, attitude = 1 }
        end
        return { state = 'enemy', confidence = 1, attitude = -1 }
      end

      local function fakeAi(enabledCards, enabledTargets)
        local selectedCards, selectedTargets = {}, {}
        local ai = { player = me, room = room, data = nil, command = nil }
        function ai:getEnabledCards()
          local ret = {}
          for _, id in ipairs(enabledCards) do
            if not table.contains(selectedCards, id) then table.insert(ret, id) end
          end
          return ret
        end
        function ai:getCardValue(id) return values[id] or 0 end
        function ai:getFactionRelation(target) return relation(target) end
        function ai:shouldProtect(target) return target == ally or target == wounded end
        function ai:selectSkill() end
        function ai:selectCard(id, selected)
          if selected then table.insertIfNeed(selectedCards, id)
          else table.removeOne(selectedCards, id) end
        end
        function ai:getSelectedTargets()
          local ret = {}
          for _, target in ipairs(selectedTargets) do table.insert(ret, target) end
          return ret
        end
        function ai:getEnabledTargets()
          local ret = {}
          for _, target in ipairs(enabledTargets) do
            if not table.contains(selectedTargets, target) then table.insert(ret, target) end
          end
          return ret
        end
        function ai:selectTarget(target, selected)
          if selected then table.insertIfNeed(selectedTargets, target)
          else table.removeOne(selectedTargets, target) end
        end
        function ai:okButtonEnabled() return #selectedTargets > 0 end
        function ai:unSelectAll()
          selectedCards, selectedTargets = {}, {}
        end
        function ai:getBenefitOfEvents(callback)
          local logic = { score = 0 }
          function logic:useCard(data)
            for _, target in ipairs(data.tos or {}) do
              if data.card and data.card.trueName == 'archery_attack' then
                if target == enemy then self.score = self.score + 100
                elseif target == ally or target == wounded then self.score = self.score - 10 end
              elseif target == enemy then self.score = self.score + 100
              elseif target == ally or target == wounded then self.score = self.score - 100 end
            end
          end
          function logic:damage(data)
            self.score = self.score + (data.to == enemy and 100 or -100)
          end
          function logic:recover(data)
            self.score = self.score + ((data.who == ally or data.who == wounded) and 100 or -100)
          end
          callback(logic)
          return logic.score
        end
        return ai
      end

      local active = Fk.Ltk.AI.ActiveStrategy
      local function strategy(name)
        local skill = Fk.skills[name]
        assert(skill, name .. ' missing from active pool')
        local list = skill:getSkeleton().ai_strategies[active]
        assert(list and #list > 0, name .. ' has no candidate AI handler')
        return list[#list]
      end
      local function run(name, command, data, cards, targets)
        local ai = fakeAi(cards, targets or {})
        ai.command, ai.data = command, data
        local reply, value = strategy(name):makeReply(ai)
        assert(reply, name .. ' must produce a bounded candidate')
        return { card = reply.card, targets = reply.targets, value = value }
      end

      local common_data = {
        nil, 'slash', '#test', true,
        { bypass_distances = true, bypass_times = true }, {},
      }
      local longdanResponse = run('hs__longdan', 'AskForResponseCard', { nil, 'slash', '#test', true, {}, {} },
        { jink_high, jink_low })
      local longdanUse = run('hs__longdan', 'AskForUseCard', common_data, { jink_low }, { enemy })
      local luanji = run('hs__luanji', 'AskForUseCard', common_data, { pair_a, pair_b }, { enemy, ally })
      local wusheng = run('hs__wusheng', 'AskForUseCard', common_data, { red_high, red_low }, { enemy })
      local huoji = run('huoji', 'AskForUseCard', common_data, { huoji_source, huoji_follow }, { enemy, ally })
      local jijiu = run('jijiu', 'AskForUseCard', {
        nil, 'peach', '#AskForPeaches:3', true, { must_targets = { ally.id } }, {},
      }, { red_low })
      local kanpo = run('kanpo', 'AskForUseCard', {
        nil, 'nullification', '#AskForNullification:1:3:duel', true,
        { effectFrom = enemy.id, effectTo = ally.id, effectCardId = effect_card }, {},
      }, { black })

      local function dispatcherBot(skill_name, command, data, cards)
        local bot = SmartAI:new(me)
        bot.room = room
        bot.handler = {
          skill_name = nil,
          scene = { getAllItems = function() return {} end },
        }
        bot.getEnabledSkills = function() return { skill_name } end
        bot.getEnabledCards = function() return cards end
        bot.getCardValue = function(_, id) return values[id] or 0 end
        bot.selectSkill = function(_, name, selected)
          if selected then bot.handler.skill_name = name
          elseif bot.handler.skill_name == name then bot.handler.skill_name = nil end
        end
        bot.selectCard = function() end
        bot.selectTarget = function() end
        bot.unSelectAll = function() bot.handler.skill_name = nil end
        bot.getFactionRelation = function(_, target) return relation(target) end
        bot.shouldProtect = function(_, target) return target == ally or target == wounded end
        bot.getBenefitOfEvents = function(_, callback)
          local logic = { score = 100 }
          function logic:recover() end
          callback(logic)
          return logic.score
        end
        bot.command, bot.data = command, data
        return bot['handle' .. command](bot, data)
      end
      local dispatcherResponse = dispatcherBot('hs__longdan', 'AskForResponseCard',
        { nil, 'slash', '#test', true, {}, {} }, { jink_high, jink_low })
      local dispatcherJijiu = dispatcherBot('jijiu', 'AskForUseCard', {
        nil, 'peach', '#AskForPeaches:' .. ally.id, true,
        { must_targets = { ally.id } }, {},
      }, { red_low })

      return {
        registered = {
          longdan = #Fk.skills.hs__longdan:getSkeleton().ai_strategies[active] > 0,
          luanji = #Fk.skills.hs__luanji:getSkeleton().ai_strategies[active] > 0,
          wusheng = #Fk.skills.hs__wusheng:getSkeleton().ai_strategies[active] > 0,
          huoji = #Fk.skills.huoji:getSkeleton().ai_strategies[active] > 0,
          jijiu = #Fk.skills.jijiu:getSkeleton().ai_strategies[active] > 0,
          kanpo = #Fk.skills.kanpo:getSkeleton().ai_strategies[active] > 0,
        },
        longdanResponse = longdanResponse,
        longdanUse = longdanUse,
        luanji = luanji,
        wusheng = wusheng,
        huoji = huoji,
        jijiu = jijiu,
        kanpo = kanpo,
        dispatcherResponse = dispatcherResponse,
        dispatcherJijiu = dispatcherJijiu,
        baselineResponse = { card = jink_high, targets = {} },
        ids = {
          jinkHigh = jink_high, jinkLow = jink_low, enemy = enemy.id,
          redLow = red_low, huojiSource = huoji_source, black = black,
          ally = ally.id,
        },
      }
    `);

    for (const [name, registered] of Object.entries(output.registered)) {
      assert.equal(registered, true, `${name} must be registered in candidate AI`);
    }
    assert.equal(output.longdanResponse.card.subcards[0], output.ids.jinkLow, JSON.stringify(output));
    assert.notEqual(output.longdanResponse.card.subcards[0], output.baselineResponse.card,
      'response strategy must improve on the first-raw-card baseline');
    assert.deepEqual(output.longdanResponse.targets, []);
    assert.deepEqual(output.longdanUse.targets, [output.ids.enemy]);
    assert.ok(output.longdanUse.value > 0);
    assert.equal(output.luanji.card.subcards.length, 2);
    assert.ok(output.luanji.targets.includes(output.ids.enemy));
    assert.ok(output.luanji.value > 0);
    assert.equal(output.wusheng.card.subcards[0], output.ids.redLow);
    assert.deepEqual(output.wusheng.targets, [output.ids.enemy], JSON.stringify(output));
    assert.ok(output.wusheng.value > 0);
    assert.equal(output.huoji.card.subcards[0], output.ids.huojiSource);
    assert.deepEqual(output.huoji.targets, [output.ids.enemy]);
    assert.ok(output.huoji.value > 0);
    assert.equal(output.jijiu.card.subcards[0], output.ids.redLow);
    assert.deepEqual(output.jijiu.targets, []);
    assert.ok(output.jijiu.value > 0);
    assert.equal(output.kanpo.card.subcards[0], output.ids.black);
    assert.deepEqual(output.kanpo.targets, []);
    assert.ok(output.kanpo.value > 0);
    assert.equal(output.dispatcherResponse.card.skill, 'hs__longdan');
    assert.equal(output.dispatcherResponse.card.subcards[0], output.ids.jinkLow);
    assert.equal(output.dispatcherJijiu.card.skill, 'jijiu');
    assert.equal(output.dispatcherJijiu.card.subcards[0], output.ids.redLow);
  } finally {
    runtime.close();
  }
});

test('Prompt 4 group 3 uses public-information targets and legal resource subsets', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });
  await runtime.start();
  try {
    const output = runtime.eval<{
      registered: Record<string, boolean>;
      aocai: { cards: number[]; value: number };
      beizhu: { targets: number[]; value: number };
      beizhuCard: number;
      dimeng: { cards: number[]; targets: number[]; value: number };
      choufa: { targets: number[]; value: number };
      choufaCard: number;
      choufaDispatch: number;
      choufaDispatchRegistered: boolean;
      choufaDispatchDirect: number;
      cunsi: { targets: number[]; value: number };
      duanfa: { cards: number[]; value: number };
      ids: Record<string, number>;
    }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')
      Fk.filtered_cards = Fk.filtered_cards or {}
      Fk.printed_cards = Fk.printed_cards or {}

      local function findCards(predicate)
        local ids = {}
        for id, card in pairs(Fk.cards) do
          if type(id) == 'number' and predicate(card) then table.insert(ids, id) end
        end
        table.sort(ids)
        return ids
      end
      local function findCard(predicate)
        return findCards(predicate)[1]
      end

      local basics = findCards(function(card) return card.type == Card.TypeBasic end)
      local blacks = findCards(function(card) return card.color == Card.Black end)
      local typed = {}
      for _, id in ipairs(findCards(function() return true end)) do
        local card = Fk:getCardById(id)
        if card and not typed[card.type] then
          typed[card.type] = { id }
        elseif card and #typed[card.type] < 3 then
          table.insert(typed[card.type], id)
        end
      end
      local type_ids = {}
      for _, ids in pairs(typed) do
        if #ids >= 2 then table.insert(type_ids, ids) end
      end
      assert(#basics >= 2 and #blacks >= 2 and #type_ids >= 1)

      local aocai_high, aocai_low = basics[1], basics[2]
      local used_cards = { [aocai_high] = true, [aocai_low] = true }
      local function takeDistinct(list, count)
        local ret = {}
        for _, id in ipairs(list) do
          if not used_cards[id] then
            used_cards[id] = true
            table.insert(ret, id)
            if #ret == count then return ret end
          end
        end
        return ret
      end
      local beizhu_pair = takeDistinct(blacks, 2)
      local duanfa_pair = takeDistinct(blacks, 2)
      assert(#beizhu_pair == 2 and #duanfa_pair == 2)
      local beizhu_card_a, beizhu_card_b = beizhu_pair[1], beizhu_pair[2]
      local duanfa_low, duanfa_high = duanfa_pair[1], duanfa_pair[2]
      local choufa_cards = { type_ids[1][1], type_ids[1][2] }
      local singleton
      for id, card in pairs(Fk.cards) do
        if type(id) == 'number' and card.type ~= Fk:getCardById(choufa_cards[1]).type then
          singleton = id
          break
        end
      end
      assert(singleton)
      table.insert(choufa_cards, singleton)

      local me = { id = 1, hp = 3, maxHp = 4, kingdom = 'wei' }
      local ally = { id = 2, hp = 2, maxHp = 4, kingdom = 'wei', hand = 1, dead = false }
      local enemy = { id = 3, hp = 3, maxHp = 4, kingdom = 'shu', hand = 1, dead = false }
      local enemy_big = { id = 4, hp = 1, maxHp = 4, kingdom = 'shu', hand = 4, dead = false }
      function me:getHandcardNum() return 3 end
      function me:getMark() return 0 end
      function ally:getHandcardNum() return self.hand end
      function enemy:getHandcardNum() return self.hand end
      function enemy_big:getHandcardNum() return self.hand end
      function ally:isKongcheng() return false end
      function enemy:isKongcheng() return false end
      function enemy_big:isKongcheng() return false end
      function ally:isAlive() return true end
      function enemy:isAlive() return true end
      function enemy_big:isAlive() return true end
      function ally:hasSkill() return false end
      function enemy:hasSkill() return false end
      function enemy_big:hasSkill() return false end
      function ally:getCardIds() return choufa_cards end

      local values = {
        [aocai_high] = 9, [aocai_low] = 1,
        [beizhu_card_a] = 2, [beizhu_card_b] = 8,
        [duanfa_low] = 1, [duanfa_high] = 60,
      }
      local function relation(target)
        if target == ally or target == me then
          return { state = 'friend', confidence = 1, attitude = 1 }
        end
        return { state = 'enemy', confidence = 1, attitude = -1 }
      end

      local function baseAi(enabledCards, enabledTargets)
        local ai = { player = me, data = nil, selectedCards = {}, selectedTargets = {} }
        function ai:getEnabledCards()
          local ret = {}
          for _, id in ipairs(enabledCards) do
            if not table.contains(self.selectedCards, id) then table.insert(ret, id) end
          end
          return ret
        end
        function ai:getCardValue(id) return values[id] or 0 end
        function ai:getFactionRelation(target) return relation(target) end
        function ai:getEnabledTargets()
          local ret = {}
          for _, target in ipairs(enabledTargets) do
            if not table.contains(self.selectedTargets, target) then table.insert(ret, target) end
          end
          return ret
        end
        function ai:selectSkill() end
        function ai:selectCard(id, selected)
          if selected then table.insertIfNeed(self.selectedCards, id)
          else table.removeOne(self.selectedCards, id) end
        end
        function ai:selectTarget(target, selected)
          if selected then table.insertIfNeed(self.selectedTargets, target)
          else table.removeOne(self.selectedTargets, target) end
        end
        function ai:unSelectAllCards() self.selectedCards = {} end
        function ai:unSelectAll() self.selectedCards, self.selectedTargets = {}, {} end
        function ai:getBenefitOfEvents(callback)
          local logic = { score = 0 }
          function logic:throwCard(cards) for _, id in ipairs(cards) do self.score = self.score - (values[id] or 0) end end
          function logic:drawCards(_, count) self.score = self.score + count * 25 end
          callback(logic)
          return logic.score
        end
        return ai
      end

      local function active(name, ai)
        local skill = assert(Fk.skills[name], name)
        local list = skill:getSkeleton().ai_strategies[Fk.Ltk.AI.ActiveStrategy]
        assert(list and #list > 0, name .. ' has no active strategy')
        return list[#list]:makeReply(ai)
      end
      local function chooser(name, ai)
        local skill = assert(Fk.skills[name], name)
        local list = skill:getSkeleton().ai_strategies[Fk.Ltk.AI.ChooseCardStrategy]
        assert(list and #list > 0, name .. ' has no choose-card strategy')
        return list[#list]:makeReply(ai)
      end

      local aocai_reply, aocai_value = active('aocai', baseAi({ aocai_high, aocai_low }, {}))
      local beizhu_ai = baseAi({}, { enemy, enemy_big })
      local beizhu_reply, beizhu_value = active('beizhu', beizhu_ai)

      local card_ai = baseAi({}, {})
      card_ai.data = { enemy_big, { card_data = { { '$Hand', { beizhu_card_a, beizhu_card_b } } } }, '#beizhu-throw:4' }
      local beizhu_card = chooser('beizhu', card_ai)

      local dimeng_ai = baseAi({ blacks[1], blacks[2], blacks[3] }, { ally, enemy_big })
      local dimeng_reply, dimeng_value = active('dimeng', dimeng_ai)

      local choufa_ai = baseAi({}, { ally, enemy })
      local choufa_reply, choufa_value = active('choufa', choufa_ai)
      local choufa_card_ai = baseAi({}, {})
      choufa_card_ai.data = { ally, 'h', '#AskForChooseCard:2::choufa' }
      local choufa_card = chooser('choufa', choufa_card_ai)

      local cunsi_reply, cunsi_value = active('cunsi', baseAi({}, { enemy, ally, me }))

      local duanfa_reply, duanfa_value = active('duanfa', baseAi({ duanfa_low, duanfa_high }, {}))

      RoomInstance = { filtered_cards = {}, printed_cards = {}, getPlayerById = function(_, id)
        if id == ally.id then return ally elseif id == enemy.id then return enemy elseif id == enemy_big.id then return enemy_big end
      end }
      local bot = SmartAI:new(me)
      bot.data = { ally, 'h', '#AskForChooseCard:2::choufa' }
      bot.command = 'AskForCardChosen'
      bot.getCardValue = function(_, id) return values[id] or 0 end
      local dispatcher_strategy = bot:findStrategyOfSkill(Fk.Ltk.AI.ChooseCardStrategy, 'choufa')
      local dispatcher_direct = dispatcher_strategy and dispatcher_strategy:makeReply(bot)
      local choufa_dispatch = bot:makeReply()

      local function normalize(ret, value)
        local card = ret and ret.card or {}
        return { cards = card.subcards or {}, targets = ret and ret.targets or {}, value = value or 0 }
      end
      return {
        registered = {
          aocai = #Fk.skills.aocai:getSkeleton().ai_strategies[Fk.Ltk.AI.ActiveStrategy] > 0,
          beizhu = #Fk.skills.beizhu:getSkeleton().ai_strategies[Fk.Ltk.AI.ActiveStrategy] > 0,
          dimeng = #Fk.skills.dimeng:getSkeleton().ai_strategies[Fk.Ltk.AI.ActiveStrategy] > 0,
          choufa = #Fk.skills.choufa:getSkeleton().ai_strategies[Fk.Ltk.AI.ActiveStrategy] > 0,
          cunsi = #Fk.skills.cunsi:getSkeleton().ai_strategies[Fk.Ltk.AI.ActiveStrategy] > 0,
          duanfa = #Fk.skills.duanfa:getSkeleton().ai_strategies[Fk.Ltk.AI.ActiveStrategy] > 0,
        },
        aocai = { cards = aocai_reply.card.subcards, value = aocai_value },
        beizhu = normalize(beizhu_reply, beizhu_value),
        beizhuCard = beizhu_card,
        dimeng = normalize(dimeng_reply, dimeng_value),
        choufa = normalize(choufa_reply, choufa_value),
        choufaCard = choufa_card,
        choufaDispatch = choufa_dispatch,
        choufaDispatchRegistered = dispatcher_strategy ~= nil,
        choufaDispatchDirect = dispatcher_direct,
        cunsi = normalize(cunsi_reply, cunsi_value),
        duanfa = { cards = duanfa_reply.card.subcards, value = duanfa_value },
        ids = {
          aocaiLow = aocai_low, beizhuCardB = beizhu_card_b, ally = ally.id,
          enemy = enemy.id, enemyBig = enemy_big.id, choufaSingleton = singleton,
          duanfaLow = duanfa_low, duanfaHigh = duanfa_high,
        },
      }
    `);

    for (const [name, registered] of Object.entries(output.registered)) {
      assert.equal(registered, true, `${name} must be registered in candidate AI`);
    }
    assert.deepEqual(output.aocai.cards, [output.ids.aocaiLow], JSON.stringify(output));
    assert.ok(output.aocai.value > 0);
    assert.deepEqual(output.beizhu.targets, [output.ids.enemy], JSON.stringify(output));
    assert.ok(output.beizhu.value > 0);
    assert.equal(output.beizhuCard, output.ids.beizhuCardB);
    assert.deepEqual(output.dimeng.targets.sort((a, b) => a - b), [output.ids.ally, output.ids.enemyBig]);
    assert.equal(output.dimeng.cards.length, 3);
    assert.ok(output.dimeng.value > 0);
    assert.deepEqual(output.choufa.targets, [output.ids.ally]);
    assert.equal(output.choufaCard, output.ids.choufaSingleton);
    assert.equal(output.choufaDispatchRegistered, true);
    assert.equal(output.choufaDispatchDirect, output.ids.choufaSingleton);
    assert.equal(output.choufaDispatch, output.ids.choufaSingleton);
    assert.deepEqual(output.cunsi.targets, [output.ids.ally]);
    assert.ok(output.cunsi.value > 0);
    assert.deepEqual(output.duanfa.cards, [output.ids.duanfaLow]);
    assert.ok(output.duanfa.value > 0);
  } finally {
    runtime.close();
  }
});
