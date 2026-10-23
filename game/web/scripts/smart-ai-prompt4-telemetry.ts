/**
 * Deterministic, metadata-only Prompt 4 telemetry.
 *
 * This is deliberately separate from observed-match telemetry.  It runs the
 * real registered AI strategies from the candidate and the pinned upstream
 * baseline against the same legal request-shaped fixtures, then records only
 * skill IDs, bounded counters, target-quality classes and aggregate resource
 * costs.  It must never be used as a win-rate estimate.
 */
import fs from 'node:fs';
import path from 'node:path';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { loadUpstreamFiles, UPSTREAM_PACKAGE_NAMES } from './upstream-packages';

const PACKAGE_FILE = /\.(lua|json|md|qml|js)$/iu;
const GROUP_SKILLS = [
  'tianyi', 'shangyi', 'tiaoxin', 'hs__zhiheng', 'hs__kurou', 'hs__qiangxi',
  'hs__longdan', 'hs__luanji', 'hs__wusheng', 'huoji', 'jijiu', 'kanpo',
  'aocai', 'beizhu', 'dimeng', 'choufa', 'cunsi', 'duanfa',
] as const;

export type Prompt4TelemetryRecord = {
  skill: string;
  surface: 'active' | 'choose_card';
  opportunity: boolean;
  candidate: {
    strategyRegistered: boolean;
    activated: boolean;
    legal: boolean;
    targetQuality: 'enemy' | 'ally' | 'ally_enemy' | 'none' | 'wrong' | 'not_applicable';
    resourceCost: number;
    value: number;
    error: string | null;
  };
  baseline: {
    strategyRegistered: boolean;
    activated: boolean;
    legal: boolean;
    targetQuality: 'enemy' | 'ally' | 'ally_enemy' | 'none' | 'wrong' | 'not_applicable';
    resourceCost: number;
    value: number;
    error: string | null;
  };
};

export type Prompt4TelemetryReport = {
  schemaVersion: 1;
  kind: 'deterministic_strategy_telemetry';
  mode: 'new_heg_mode';
  candidateSource: 'local-runtime';
  baselineSource: 'pinned-scratch-upstream';
  skills: readonly string[];
  records: Prompt4TelemetryRecord[];
  summary: {
    scenarioCount: number;
    opportunityCount: number;
    candidateActivationCount: number;
    candidateMissCount: number;
    candidateLegalCount: number;
    candidateTargetQualityRate: number | null;
    baselineActivationCount: number;
    baselineLegalCount: number;
    candidateResourceCost: number;
    baselineResourceCost: number;
    candidateTargetQualitySuccessCount: number;
    candidateLowerResourceCostCount: number;
    winRateAvailable: false;
  };
  limitations: string[];
};

function mountLocalRuntime(): Map<string, Uint8Array> {
  const packagesRoot = path.resolve(process.cwd(), '../../runtime/packages');
  const files = new Map<string, Uint8Array>();
  function visit(directory: string): void {
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

const LUA_TELEMETRY = String.raw`
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

local basic = findCards(function(card) return card.type == Card.TypeBasic end)
local reds = findCards(function(card) return card.color == Card.Red and card.type ~= Card.TypeEquip end)
local blacks = findCards(function(card) return card.color == Card.Black and card.type ~= Card.TypeEquip end)
local jinks = findCards(function(card) return card.trueName == 'jink' end)
local slash = findCard(function(card) return card.trueName == 'slash' end)
local peach = findCard(function(card) return card.trueName == 'peach' end)
local duel = findCard(function(card) return card.trueName == 'duel' end)
local weapon = findCard(function(card) return card.sub_type == Card.SubtypeWeapon end)
local high_number = findCard(function(card) return type(card.number) == 'number' and card.number >= 13 end)
assert(#basic >= 4 and #reds >= 4 and #blacks >= 3 and #jinks >= 2 and slash and peach and duel and weapon)
assert(high_number)

local pair_a, pair_b
for _, id in ipairs(findCards(function(card) return card:getSuitString(true) ~= 'log_nosuit' end)) do
  if not pair_a then pair_a = id
  elseif Fk:getCardById(id):getSuitString(true) ~= Fk:getCardById(pair_a):getSuitString(true) then
    pair_b = id
    break
  end
end
assert(pair_a and pair_b)

local same_suit_a, same_suit_b
for _, id in ipairs(reds) do
  for _, other in ipairs(reds) do
    if id ~= other and Fk:getCardById(id):getSuitString(true) == Fk:getCardById(other):getSuitString(true) then
      same_suit_a, same_suit_b = id, other
      break
    end
  end
  if same_suit_a then break end
end
assert(same_suit_a and same_suit_b)

local me = { id = 1, hp = 3, maxHp = 4, kingdom = 'wei', phase = Player.Play }
local enemy = { id = 2, hp = 2, maxHp = 4, kingdom = 'shu', hand = 4, dead = false }
local ally = { id = 3, hp = 2, maxHp = 4, kingdom = 'wei', hand = 3, dead = false }
local enemy_small = { id = 4, hp = 1, maxHp = 4, kingdom = 'shu', hand = 1, dead = false }
local players = { me, enemy, ally, enemy_small }
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

local function installPlayerMethods(player)
  function player:getCardIds(zone)
    if zone == 'e' then return self.equip_ids or {} end
    return self.hand_ids or {}
  end
  function player:getHandcardNum() return self.hand or #(self.hand_ids or {}) end
  function player:getMark(name) return self.marks and (self.marks[name] or 0) or 0 end
  function player:getTableMark(name) return self.table_marks and (self.table_marks[name] or {}) or {} end
  function player:prohibitDiscard() return false end
  function player:prohibitUse() return false end
  function player:isProhibited() return false end
  function player:isKongcheng() return self:getHandcardNum() == 0 end
  function player:isNude() return self:isKongcheng() and #(self.equip_ids or {}) == 0 end
  function player:isWounded() return self.hp < self.maxHp end
  function player:isAlive() return not self.dead end
  function player:hasSkill() return false end
  function player:canUse() return true end
end
for _, player in ipairs(players) do installPlayerMethods(player) end

local values = {}
for _, id in ipairs(basic) do values[id] = 7 end
for _, id in ipairs(reds) do values[id] = 7 end
for _, id in ipairs(blacks) do values[id] = 7 end
values[basic[1]], values[basic[2]], values[basic[3]], values[basic[4]] = 1, 9, 3, 8
values[reds[1]], values[reds[2]], values[reds[3]], values[reds[4]] = 1, 9, 3, 8
values[blacks[1]], values[blacks[2]], values[blacks[3]] = 1, 9, 3
values[jinks[1]], values[jinks[2]] = 9, 1
values[weapon] = 8
values[pair_a], values[pair_b] = 1, 1

local function relation(target)
  if target == ally or target == me then return { state = 'friend', confidence = 1, attitude = 1 } end
  return { state = 'enemy', confidence = 1, attitude = -1 }
end

local function resetPlayerState()
  me.hp, me.maxHp, me.hand = 3, 4, 4
  me.hand_ids, me.equip_ids, me.marks, me.table_marks = { high_number, basic[1], slash, weapon }, {}, {}, {}
  enemy.hp, enemy.hand, enemy.dead = 2, 4, false
  ally.hp, ally.hand, ally.dead = 2, 1, false
  enemy_small.hp, enemy_small.hand, enemy_small.dead = 1, 1, false
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
  function ai:shouldProtect(target) return target == ally or target == me end
  function ai:selectSkill() end
  function ai:selectCard(id, selected)
    if selected then table.insertIfNeed(selectedCards, id)
    else table.removeOne(selectedCards, id) end
  end
  function ai:selectTarget(target, selected)
    if selected then table.insertIfNeed(selectedTargets, target)
    else table.removeOne(selectedTargets, target) end
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
  function ai:okButtonEnabled() return #selectedTargets > 0 end
  function ai:unSelectAll() selectedCards, selectedTargets = {}, {} end
  function ai:unSelectAllCards() selectedCards = {} end
  function ai:getBenefitOfEvents(callback)
    local logic = { score = 0 }
    function logic:throwCard(cards)
      for _, id in ipairs(cards or {}) do self.score = self.score - (values[id] or 0) * 12 end
    end
    function logic:drawCards(_, count) self.score = self.score + (count or 0) * 25 end
    function logic:loseHp(_, count) self.score = self.score - (count or 1) * 40 end
    function logic:damage(data) self.score = self.score + (data.to == enemy and 120 or -100) end
    function logic:recover(data) self.score = self.score + ((data.who == ally or data.who == me) and 100 or -100) end
    function logic:useCard(data)
      for _, target in ipairs(data.tos or {}) do
        if data.card and data.card.trueName == 'archery_attack' then
          self.score = self.score + (target == enemy and 100 or -10)
        else
          self.score = self.score + (target == enemy and 100 or -100)
        end
      end
    end
    callback(logic)
    return logic.score
  end
  return ai
end

local function strategy(name, strategyType)
  local skill = Fk.skills[name]
  if not skill then return nil end
  local list = skill:getSkeleton().ai_strategies[strategyType]
  return list and list[#list] or nil
end

local function normalize(ret, value)
  local card = ret and ret.card or {}
  return {
    cards = card.subcards or {},
    targets = ret and ret.targets or {},
    value = type(value) == 'number' and value or 0,
  }
end

local function cardCost(cards)
  local cost = 0
  for _, id in ipairs(cards or {}) do cost = cost + (values[id] or 0) end
  return cost
end

local function resourceCost(skillName, cards)
  local cost = cardCost(cards)
  -- Qiangxi has two legal costs: discard one weapon or lose one HP.  The
  -- latter is represented as a bounded 40-point resource unit so the report
  -- does not mistake a legal zero-card HP payment for a free activation.
  if skillName == 'hs__qiangxi' and #(cards or {}) == 0 then cost = cost + 40 end
  return cost
end

local function targetQuality(targets, expected)
  if expected == 'none' then return #targets == 0 and 'none' or 'wrong' end
  local has_enemy, has_ally = false, false
  for _, target in ipairs(targets or {}) do
    local id = type(target) == 'table' and target.id or target
    if id == enemy.id or id == enemy_small.id then has_enemy = true end
    if id == ally.id or id == me.id then has_ally = true end
  end
  if expected == 'enemy' then return has_enemy and 'enemy' or 'wrong' end
  if expected == 'ally' then return has_ally and 'ally' or 'wrong' end
  if expected == 'ally_enemy' then return has_enemy and has_ally and 'ally_enemy' or 'wrong' end
  return 'not_applicable'
end

local function countMatches(actual, expected)
  if expected == nil then return true end
  if type(expected) == 'number' then return actual == expected end
  if type(expected) == 'table' then
    for _, count in ipairs(expected) do if actual == count then return true end end
  end
  return false
end

local function firstExpectedCount(expected)
  if type(expected) == 'number' then return expected end
  if type(expected) == 'table' then return expected[1] or 0 end
  return 0
end

local function legal(reply, cards, targets, expectedCards, expectedTargets)
  if not reply then return false end
  for _, id in ipairs(reply.cards or {}) do if not table.contains(cards, id) then return false end end
  for _, target in ipairs(reply.targets or {}) do
    local target_id = type(target) == 'table' and target.id or target
    local found = false
    for _, allowed in ipairs(targets) do
      local allowed_id = type(allowed) == 'table' and allowed.id or allowed
      if target_id == allowed_id then found = true break end
    end
    if not found then return false end
  end
  if not countMatches(#reply.cards, expectedCards) then return false end
  if not countMatches(#reply.targets, expectedTargets) then return false end
  return true
end

local function baseline(cards, targets, expectedCards, expectedTargets)
  local selected_cards = {}
  local selected_targets = {}
  for i = 1, math.min(firstExpectedCount(expectedCards), #cards) do table.insert(selected_cards, cards[i]) end
  for i = 1, math.min(firstExpectedCount(expectedTargets), #targets) do table.insert(selected_targets, targets[i]) end
  return { cards = selected_cards, targets = selected_targets, value = 0 }
end

local function activeCase(skillName, data, command, cards, targets, expected, expectedCards, expectedTargets)
  resetPlayerState()
  local ai = fakeAi(cards, targets)
  ai.command, ai.data = command, data
  local registered = strategy(skillName, Fk.Ltk.AI.ActiveStrategy)
  local reply, value, error_message
  if registered then
    local ok, ret, ret_value = pcall(function() return registered:makeReply(ai) end)
    if ok then reply, value = ret, ret_value else error_message = 'strategy_error' end
  end
  local normalized = normalize(reply, value)
  local baseline_reply = baseline(cards, targets, expectedCards, expectedTargets)
  local candidate_legal = legal(normalized, cards, targets, expectedCards, expectedTargets)
  local baseline_legal = legal(baseline_reply, cards, targets, expectedCards, expectedTargets)
  return {
    skill = skillName, surface = 'active', opportunity = true,
    candidate = {
      strategyRegistered = registered ~= nil, activated = reply ~= nil, legal = candidate_legal,
      targetQuality = targetQuality(normalized.targets, expected), resourceCost = resourceCost(skillName, normalized.cards),
      value = normalized.value, error = error_message,
    },
    baseline = {
      strategyRegistered = false, activated = true, legal = baseline_legal,
      targetQuality = targetQuality(baseline_reply.targets, expected), resourceCost = resourceCost(skillName, baseline_reply.cards),
      value = 0, error = nil,
    },
  }
end

local function chooseCase(skillName, data, target, cards, expected)
  resetPlayerState()
  target.hand_ids = cards
  local ai = fakeAi({}, {})
  ai.data = data
  local registered = strategy(skillName, Fk.Ltk.AI.ChooseCardStrategy)
  local chosen, value, error_message
  if registered then
    local ok, ret, ret_value = pcall(function() return registered:makeReply(ai) end)
    if ok then chosen, value = ret, ret_value else error_message = 'strategy_error' end
  end
  local visible = {}
  for _, id in ipairs(cards) do table.insert(visible, id) end
  local candidate_legal = chosen ~= nil and table.contains(visible, chosen)
  local baseline_card = visible[1]
  local baseline_legal = baseline_card ~= nil
  local candidate_cost = chosen and (values[chosen] or 0) or 0
  local baseline_cost = baseline_card and (values[baseline_card] or 0) or 0
  return {
    skill = skillName, surface = 'choose_card', opportunity = true,
    candidate = {
      strategyRegistered = registered ~= nil, activated = chosen ~= nil, legal = candidate_legal,
      targetQuality = 'not_applicable', resourceCost = candidate_cost, value = value or 0, error = error_message,
    },
    baseline = {
      strategyRegistered = false, activated = baseline_card ~= nil, legal = baseline_legal,
      targetQuality = 'not_applicable', resourceCost = baseline_cost, value = 0, error = nil,
    },
  }
end

local cases = {}
local function addActive(...) table.insert(cases, activeCase(...)) end
local function addChoose(...) table.insert(cases, chooseCase(...)) end
local common_data = { nil, 'slash', '#prompt', true, { bypass_distances = true, bypass_times = true }, {} }

me.hand_ids = { basic[1], basic[2], slash, weapon }
addActive('tianyi', common_data, 'AskForUseCard', { basic[2] }, { enemy, enemy_small }, 'enemy', 0, 1)
addActive('shangyi', common_data, 'AskForUseCard', {}, { enemy, enemy_small }, 'enemy', 0, 1)
addActive('tiaoxin', common_data, 'AskForUseCard', {}, { enemy, enemy_small }, 'enemy', 0, 1)
addActive('hs__zhiheng', common_data, 'AskForUseCard', { basic[2], basic[1] }, {}, 'none', 1, 0)
addActive('hs__kurou', common_data, 'AskForUseCard', { basic[2], basic[1] }, {}, 'none', 1, 0)
addActive('hs__qiangxi', common_data, 'AskForUseCard', { weapon }, { enemy, enemy_small }, 'enemy', { 0, 1 }, 1)
addActive('hs__longdan', { nil, 'slash', '#response', true, {}, {} }, 'AskForResponseCard', { jinks[1], jinks[2] }, {}, 'none', 1, 0)
addActive('hs__luanji', common_data, 'AskForUseCard', { pair_a, pair_b }, { enemy, ally, enemy_small }, 'enemy', 2, 3)
addActive('hs__wusheng', common_data, 'AskForUseCard', { reds[1], reds[2] }, { enemy, enemy_small }, 'enemy', 1, 1)
addActive('huoji', common_data, 'AskForUseCard', { same_suit_a, same_suit_b }, { enemy, ally }, 'enemy', 1, 1)
addActive('jijiu', { nil, 'peach', '#AskForPeaches:3', true, { must_targets = { ally.id } }, {} }, 'AskForUseCard', { reds[1] }, {}, 'none', 1, 0)
addActive('kanpo', { nil, 'nullification', '#AskForNullification:1:3:duel', true, { effectFrom = enemy.id, effectTo = ally.id, effectCardId = duel }, {} }, 'AskForUseCard', { blacks[1] }, {}, 'none', 1, 0)
addActive('aocai', { nil, 'slash', '#aocai', true, {}, {} }, 'AskForResponseCard', { basic[3], basic[4] }, {}, 'none', 1, 0)
addActive('beizhu', common_data, 'AskForUseCard', {}, { enemy, enemy_small }, 'enemy', 0, 1)
addActive('dimeng', common_data, 'AskForUseCard', { blacks[1], blacks[2], blacks[3] }, { ally, enemy }, 'ally_enemy', 3, 2)
addActive('choufa', common_data, 'AskForUseCard', {}, { enemy, ally }, 'ally', 0, 1)
addActive('cunsi', common_data, 'AskForUseCard', {}, { enemy, ally, me }, 'ally', 0, 1)
me.marks['duanfa-phase'] = 0
addActive('duanfa', common_data, 'AskForUseCard', { blacks[1], blacks[2] }, {}, 'none', 1, 0)

local beizhu_visible = { black = blacks[1], red = reds[1] }
addChoose('beizhu', { enemy, { card_data = { { '$Hand', { beizhu_visible.black, beizhu_visible.red } } } }, '#beizhu-throw:2' }, enemy, { beizhu_visible.black, beizhu_visible.red }, 'none')
addChoose('choufa', { ally, 'h', '#AskForChooseCard:2::choufa' }, ally, { reds[1], reds[2], blacks[1] }, 'none')

local function isBetterTarget(candidate, baseline)
  local score = { enemy = 3, ally_enemy = 3, ally = 2, none = 1, not_applicable = 0, wrong = -1 }
  return (score[candidate] or -1) > (score[baseline] or -1)
end

local summary = {
  scenarioCount = #cases, opportunityCount = 0, candidateActivationCount = 0,
  candidateMissCount = 0, candidateLegalCount = 0, candidateTargetQualityRate = nil,
  baselineActivationCount = 0, baselineLegalCount = 0, candidateResourceCost = 0,
  baselineResourceCost = 0, candidateTargetQualitySuccessCount = 0, candidateLowerResourceCostCount = 0,
  winRateAvailable = false,
}
local quality_count = 0
for _, item in ipairs(cases) do
  if item.opportunity then summary.opportunityCount = summary.opportunityCount + 1 end
  if item.candidate.activated then summary.candidateActivationCount = summary.candidateActivationCount + 1 end
  if item.opportunity and not item.candidate.activated then summary.candidateMissCount = summary.candidateMissCount + 1 end
  if item.candidate.legal then summary.candidateLegalCount = summary.candidateLegalCount + 1 end
  if item.candidate.targetQuality ~= 'not_applicable' then
    quality_count = quality_count + 1
    if item.candidate.targetQuality ~= 'wrong' then summary.candidateTargetQualitySuccessCount = summary.candidateTargetQualitySuccessCount + 1 end
  end
  if item.baseline.activated then summary.baselineActivationCount = summary.baselineActivationCount + 1 end
  if item.baseline.legal then summary.baselineLegalCount = summary.baselineLegalCount + 1 end
  summary.candidateResourceCost = summary.candidateResourceCost + item.candidate.resourceCost
  summary.baselineResourceCost = summary.baselineResourceCost + item.baseline.resourceCost
  if item.candidate.resourceCost < item.baseline.resourceCost then summary.candidateLowerResourceCostCount = summary.candidateLowerResourceCostCount + 1 end
end
if quality_count > 0 then summary.candidateTargetQualityRate = summary.candidateTargetQualitySuccessCount / quality_count end

return {
  schemaVersion = 1,
  kind = 'deterministic_strategy_telemetry',
  mode = 'new_heg_mode',
  candidateSource = 'local-runtime',
  baselineSource = 'pinned-scratch-upstream',
  skills = {
    'tianyi', 'shangyi', 'tiaoxin', 'hs__zhiheng', 'hs__kurou', 'hs__qiangxi',
    'hs__longdan', 'hs__luanji', 'hs__wusheng', 'huoji', 'jijiu', 'kanpo',
    'aocai', 'beizhu', 'dimeng', 'choufa', 'cunsi', 'duanfa',
  },
  records = cases,
  summary = summary,
  limitations = {
    'Deterministic request-shaped fixtures are not observed gameplay matches.',
    'Baseline is a first-legal/raw-card policy, not a historical native replay.',
    'No win-rate or end-to-end GameOver outcome is inferred from these records.',
    'Card and target identities are intentionally omitted from the returned evidence.',
  },
}
`;

async function runOne(files: Map<string, Uint8Array>): Promise<Prompt4TelemetryReport> {
  const runtime = new LuaRuntime({
    files,
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });
  await runtime.start();
  try {
    const report = runtime.eval<Prompt4TelemetryReport>(LUA_TELEMETRY);
    // Lua omits nil-valued table fields during JSON conversion.  Normalize
    // the bounded error slot so consumers can distinguish "no error" from a
    // missing record without exposing raw exception text.
    for (const record of report.records) {
      record.candidate.error ??= null;
      record.baseline.error ??= null;
    }
    return report;
  } finally {
    runtime.close();
  }
}

function merge(candidate: Prompt4TelemetryReport, baseline: Prompt4TelemetryReport): Prompt4TelemetryReport {
  const baselineByKey = new Map(baseline.records.map(record => [`${record.skill}:${record.surface}`, record]));
  for (const record of candidate.records) {
    const baselineRecord = baselineByKey.get(`${record.skill}:${record.surface}`);
    if (baselineRecord?.candidate.strategyRegistered) {
      throw new Error(`pinned baseline unexpectedly has a strategy for ${record.skill}:${record.surface}`);
    }
  }
  // `record.baseline` is the explicit first-legal/raw-card policy from the
  // same request fixture.  The pinned run above verifies that the upstream
  // skill itself has no dedicated strategy; it must not replace this policy
  // with a second nil-strategy result.
  return candidate;
}

export async function runPrompt4Telemetry(): Promise<Prompt4TelemetryReport> {
  const baseline = await runOne(loadUpstreamFiles(
    path.resolve(process.cwd(), '../../scratch/upstream'), UPSTREAM_PACKAGE_NAMES,
  ));
  const candidate = await runOne(mountLocalRuntime());
  return merge(candidate, baseline);
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) {
  runPrompt4Telemetry().then(report => process.stdout.write(`${JSON.stringify(report, null, 2)}\n`));
}
