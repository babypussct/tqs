import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { loadUpstreamFiles, UPSTREAM_PACKAGE_NAMES } from './upstream-packages';

const PACKAGE_FILE = /\.(lua|json|md|qml|js)$/iu;

function packageFiles(): Map<string, Uint8Array> {
  const root = path.resolve(process.cwd(), '../../runtime/packages');
  const files = new Map<string, Uint8Array>();
  function visit(directory: string) {
    for (const item of fs.readdirSync(directory, { withFileTypes: true })) {
      if (item.name === '.git') continue;
      const absolute = path.join(directory, item.name);
      if (item.isDirectory()) visit(absolute);
      else if (item.isFile() && PACKAGE_FILE.test(item.name)) {
        files.set(`packages/${path.relative(root, absolute).split(path.sep).join('/')}`, fs.readFileSync(absolute));
      }
    }
  }
  for (const item of fs.readdirSync(root, { withFileTypes: true })) {
    if (item.isDirectory()) visit(path.join(root, item.name));
  }
  return files;
}

const fixture = String.raw`
  FileIO.cd('packages/freekill-core')
  dofile('ltk/server/ai/init.lua')
  FileIO.cd('../..')
  local Pair = require('ltk.server.ai.general_pair')

  local function mk(name, kingdom, hp, skills, opts)
    opts = opts or {}
    return {
      name = name, kingdom = kingdom, subkingdom = opts.subkingdom,
      maxHp = hp, mainMaxHpAdjustedValue = opts.mainHp or 0,
      deputyMaxHpAdjustedValue = opts.deputyHp or 0,
      getSkillNameList = function() return skills end,
      isCompanionWith = function(_, other) return opts.companion == other.name end,
    }
  end
  local invented = {
    qa_pair_attack = mk('qa_pair_attack', 'wei', 4, {'hs__paoxiao'}),
    qa_pair_slash = mk('qa_pair_slash', 'wei', 4, {'hs__wusheng'}),
    qa_pair_setup = mk('qa_pair_setup', 'wei', 4, {'hs__guanxing'}),
    qa_pair_draw = mk('qa_pair_draw', 'wei', 4, {'hs__luoshen'}),
    qa_pair_blank = mk('qa_pair_blank', 'wei', 3, {'qa_unknown'}),
    qa_pair_slot = mk('qa_pair_slot', 'wei', 4, {'qa_main_only'}, {mainHp = 2, deputyHp = -1}),
    qa_pair_slot_equal = mk('qa_pair_slot_equal', 'wei', 4, {'qa_main_only'}),
    qa_pair_deputy_only = mk('qa_pair_deputy_only', 'wei', 4, {'qa_deputy_only'}),
    qa_pair_comp = mk('qa_pair_comp', 'wei', 4, {'hs__qianxun'}, {companion = 'qa_pair_attack'}),
    qa_pair_shu = mk('qa_pair_shu', 'shu', 5, {'hs__buqu'}),
    qa_pair_wild = mk('qa_pair_wild', 'wild', 4, {'hs__xiaoji'}),
    qa_pair_dual = mk('qa_pair_dual', 'shu', 4, {'hs__yiji'}, {subkingdom = 'wei'}),
    qa_pair_dual_two = mk('qa_pair_dual_two', 'wei', 4, {'hs__zhiheng'}, {subkingdom = 'shu'}),
    qa_pair_shared_one = mk('qa_pair_shared_one', 'wei', 4, {'hs__paoxiao'}),
    qa_pair_shared_two = mk('qa_pair_shared_two', 'wei', 4, {'hs__paoxiao'}),
    qa_pair_incomplete = mk('qa_pair_incomplete', 'wei', 4, {'hs__qianxun'}),
    qa_pair_incomplete_two = mk('qa_pair_incomplete_two', 'wei', 4, {'hs__luoshen'}),
  }
  invented.qa_pair_incomplete.maxHp = nil
  invented.qa_pair_incomplete_two.maxHp = nil
  for name, g in pairs(invented) do Fk.generals[name] = g end
  for _, name in ipairs({'hs__paoxiao','hs__wusheng','hs__guanxing','hs__luoshen',
      'qa_unknown','qa_main_only','qa_deputy_only','hs__qianxun','hs__buqu',
      'hs__xiaoji','hs__yiji','hs__zhiheng'}) do
    Fk.skills[name] = {hasTag = function(_, tag)
      return (name == 'qa_main_only' and tag == Skill.MainPlace) or
        (name == 'qa_deputy_only' and tag == Skill.DeputyPlace)
    end}
  end
  local function dialog(generals, kingdoms)
    return {component={name='ChooseInitialGeneralBox', model={
      name='ChooseInitialGeneralModel', prop={
        hegemony=true, choiceNum=2, generals=generals,
        enabledKingdoms=kingdoms or {'wei','shu'}
      }
    }}}
  end
  local all = {'qa_pair_attack','qa_pair_slash','qa_pair_setup','qa_pair_draw',
    'qa_pair_blank','qa_pair_slot','qa_pair_comp','qa_pair_shu',
    'qa_pair_wild','qa_pair_dual'}
  local player = {id=1}
  local ai = SmartAI:new(player)
  ai.room = { getTag=function() end, setTag=function() end, request_handlers={} }
  local function make(data)
    ai.command='CustomDialog'; ai.data=data
    return ai:makeReply()
  end
`;

test('initial Hegemony CustomDialog: legal ordered pair, fallback and schema', async () => {
  const runtime = new LuaRuntime({files: packageFiles(), callbacks: {send() {}, ui() {}, setup() {}, log() {}}});
  await runtime.start();
  try {
    const output = runtime.eval<{
      legal: boolean; stable: boolean; unsupported: string; missing: string;
      zero: string; invalid: boolean; reversed: boolean;
      chosen: string; reScore: number; swapped: number;
    }>(`${fixture}
      local candidates=dialog(all)
      local result=make(candidates)
      local valid=Pair.validate(candidates,result)
      local stable=table.concat(result,';') == table.concat(make(candidates),';')
      local chosen=result[1]
      local wrong={component={name='KnownBothBox'}}
      local unsupported=make(wrong)
      local missing=make(dialog({'qa_pair_attack','qa_missing'}, {'wei'}))
      local zero=make(dialog({'qa_pair_attack','qa_pair_shu'}, {'wei','shu'}))
      local invalid=Pair.validate(candidates, {'qa_pair_attack,qa_pair_shu','kingdom,wei'})
      local reversed = Pair.validate(dialog({'qa_pair_dual','qa_pair_attack'}, {'wei','shu'}),
        {'qa_pair_dual,qa_pair_attack','kingdom,wei'})
      local reScore=Pair.score('qa_pair_slot','qa_pair_attack')
      local swapped=Pair.score('qa_pair_attack','qa_pair_slot')
      return {legal=valid,stable=stable,unsupported=unsupported,missing=missing,
        zero=zero,invalid=invalid,reversed=reversed,chosen=chosen,
        reScore=reScore,swapped=swapped}
    `);
    assert.equal(output.legal, true);
    assert.equal(output.stable, true);
    assert.equal(output.unsupported, '__cancel');
    assert.equal(output.missing, '__cancel');
    assert.equal(output.zero, '__cancel');
    assert.equal(output.invalid, false);
    assert.equal(output.reversed, true);
    assert.notEqual(output.reScore, output.swapped, 'main/deputy modifiers should change score');
    assert.match(output.chosen, /^qa_pair_\w+,qa_pair_\w+$/u);
  } finally { runtime.close(); }
});

test('supported Hegemony CustomDialog classifies malformed non-nil replies and nil fallback through makeReply', async () => {
  const runtime = new LuaRuntime({files: packageFiles(), callbacks: {send() {}, ui() {}, setup() {}, log() {}}});
  await runtime.start();
  try {
    const report = runtime.eval<{
      total: number; fallback: number; invalid: number; no_decision: number;
      accepted: number; reasonInvalid: number; reasonStrategy: number;
      reasonDecision: number; stable: boolean;
    }>(`${fixture}
      local offer = dialog({'qa_pair_attack','qa_pair_slash'}, {'wei'})
      local good = Pair.choose(offer)
      assert(Pair.validate(offer, good))
      local tags = {}
      ai.room = {
        request_handlers = {},
        getTag = function(_, key) return tags[key] end,
        setTag = function(_, key, value) tags[key] = value end,
        getSettings = function() return nil end,
      }
      ai.command = 'CustomDialog'
      ai.data = offer
      local function check(label, expectedShape, expectedReason)
        local result = ai:makeReply()
        local shape = result == '__cancel' and 'cancel' or type(result)
        assert(shape == expectedShape, 'shape drift: ' .. label)
        assert(ai._ai_last_metric_reason == expectedReason, 'reason drift: ' .. label)
        assert(ai._ai_last_metric_detail == 'none', 'detail drift: ' .. label)
        if expectedShape == 'table' then assert(Pair.validate(ai.data, result)) end
        return result
      end
      local realFirst = check('real_strategy', 'table', 'accepted')
      local realSecond = check('strategy_stable', 'table', 'accepted')
      local stable = table.concat(realFirst, ';') == table.concat(realSecond, ';')
      local injected, nilReason
      ai.handleCustomDialog = function(self)
        if nilReason then self:markFallback(nilReason) end
        return injected
      end
      local main = good[1]:match('^([^,]+),')
      injected = {main .. ',' .. main, good[2]}
      check('duplicate', 'cancel', 'invalid_reply')
      injected = {main .. ',qa_unoffered', good[2]}
      check('unoffered', 'cancel', 'invalid_reply')
      injected = {good[1], 'kingdom,shu'}
      check('disabled', 'cancel', 'invalid_reply')
      injected = 'forged'
      check('type', 'cancel', 'invalid_reply')
      injected = {good[1]}
      check('missing', 'cancel', 'invalid_reply')
      injected = good
      ai.data = dialog({'qa_pair_attack','qa_not_in_registry'}, {'wei'})
      check('invalid_offer', 'cancel', 'invalid_reply')
      ai.data = offer
      injected, nilReason = nil, 'no_strategy'
      check('no_strategy', 'cancel', 'no_strategy')
      nilReason = nil
      check('no_decision', 'cancel', 'no_decision')
      local metrics = ai:getResponseMetrics()
      return {
        total = metrics.total, fallback = metrics.fallback,
        invalid = metrics.invalid, no_decision = metrics.no_decision,
        accepted = metrics.total - metrics.fallback,
        reasonInvalid = metrics.fallback_reasons.invalid_reply or 0,
        reasonStrategy = metrics.fallback_reasons.no_strategy or 0,
        reasonDecision = metrics.fallback_reasons.no_decision or 0,
        stable = stable,
      }
    `);
    assert.deepEqual(report, {
      total: 10, fallback: 8, invalid: 6, no_decision: 2,
      accepted: 2, reasonInvalid: 6, reasonStrategy: 1,
      reasonDecision: 1, stable: true,
    });
  } finally { runtime.close(); }
});

test('Hegemony pair accepts any lawful kingdom and respects wild, slot tags and stable ties', async () => {
  const runtime = new LuaRuntime({files: packageFiles(), callbacks: {send() {}, ui() {}, setup() {}, log() {}}});
  await runtime.start();
  try {
    const report = runtime.eval<{
      dualA: boolean; dualB: boolean; dualInvalid: boolean;
      wildMain: boolean; wildDeputy: boolean; disabledKingdom: boolean;
      slotMain: number; slotDeputy: number; deputyMain: number; deputyDeputy: number;
      companion: number; withoutCompanion: number;
      stableOrder: boolean; stableDuplicate: boolean; tieStable: boolean;
      unknownFinite: boolean; noKingdom: boolean; malformed: boolean;
      duplicatePower: number; duplicateSynergy: number;
      incompleteFallback: boolean; scorablePreferred: boolean;
      allScoringBrokenLegal: boolean; allScoringBrokenStable: boolean;
    }>(`${fixture}
      local dual=dialog({'qa_pair_dual','qa_pair_dual_two'}, {'wei','shu'})
      local dualA=Pair.validate(dual, {'qa_pair_dual,qa_pair_dual_two','kingdom,wei'})
      local dualB=Pair.validate(dual, {'qa_pair_dual,qa_pair_dual_two','kingdom,shu'})
      local dualInvalid=Pair.validate(dual, {'qa_pair_dual,qa_pair_dual_two','kingdom,wu'})
      local wild=dialog({'qa_pair_wild','qa_pair_attack'}, {'wei'})
      local wildMain=Pair.validate(wild, {'qa_pair_wild,qa_pair_attack','kingdom,wei'})
      local wildDeputy=Pair.validate(wild, {'qa_pair_attack,qa_pair_wild','kingdom,wei'})
      local disabledKingdom=Pair.choose(dialog({'qa_pair_wild','qa_pair_attack'}, {'shu'})) == nil
      local slotMain=Pair.score('qa_pair_slot_equal','qa_pair_blank')
      local slotDeputy=Pair.score('qa_pair_blank','qa_pair_slot_equal')
      local deputyMain=Pair.score('qa_pair_deputy_only','qa_pair_blank')
      local deputyDeputy=Pair.score('qa_pair_blank','qa_pair_deputy_only')
      local companion=select(2,Pair.score('qa_pair_comp','qa_pair_attack')).hegemony
      local withoutCompanion=select(2,Pair.score('qa_pair_comp','qa_pair_blank')).hegemony
      local initial=Pair.choose(dialog(all))
      local reversed={table.unpack(all)}
      for i=1,math.floor(#reversed/2) do
        reversed[i],reversed[#reversed+1-i]=reversed[#reversed+1-i],reversed[i]
      end
      local reordered=Pair.choose(dialog(reversed))
      local duplicate={table.unpack(all)}
      duplicate[#duplicate+1]='qa_pair_attack'
      local withDuplicate=Pair.choose(dialog(duplicate))
      local _, duplicateStats=Pair.score('qa_pair_shared_one','qa_pair_shared_two')
      local broken=dialog({'qa_pair_attack','qa_pair_incomplete'}, {'wei'})
      local fallback=Pair.choose(broken)
      local incompleteFallback=Pair.validate(broken,fallback)
      local mixed=Pair.choose(dialog({'qa_pair_attack','qa_pair_slash','qa_pair_incomplete'}, {'wei'}))
      local scorablePreferred=not mixed[1]:find('qa_pair_incomplete',1,true)
      local allBroken=dialog({'qa_pair_incomplete','qa_pair_incomplete_two'}, {'wei'})
      local allBrokenReversed=dialog({'qa_pair_incomplete_two','qa_pair_incomplete'}, {'wei'})
      local allBrokenResult=Pair.choose(allBroken)
      local allScoringBrokenLegal=Pair.validate(allBroken,allBrokenResult)
      local allScoringBrokenStable=table.concat(allBrokenResult,';')==
        table.concat(Pair.choose(allBrokenReversed),';')
      local unknownFinite=Pair.score('qa_pair_blank','qa_pair_shu') < math.huge
      local tied=dialog({'qa_pair_attack','qa_pair_slash'}, {'wei'})
      local tiedA=Pair.choose(tied)
      local tiedB=Pair.choose(dialog({'qa_pair_slash','qa_pair_attack'}, {'wei'}))
      return {dualA=dualA,dualB=dualB,dualInvalid=dualInvalid,
        wildMain=wildMain,wildDeputy=wildDeputy,disabledKingdom=disabledKingdom,
        slotMain=slotMain,slotDeputy=slotDeputy,
        deputyMain=deputyMain,deputyDeputy=deputyDeputy,companion=companion,
        withoutCompanion=withoutCompanion,
        stableOrder=table.concat(initial,';')==table.concat(reordered,';'),
        stableDuplicate=table.concat(initial,';')==table.concat(withDuplicate,';'),
        tieStable=table.concat(tiedA,';')==table.concat(tiedB,';'),
        unknownFinite=unknownFinite,
        duplicatePower=duplicateStats.individual,
        duplicateSynergy=duplicateStats.synergy,
        incompleteFallback=incompleteFallback,scorablePreferred=scorablePreferred,
        allScoringBrokenLegal=allScoringBrokenLegal,
        allScoringBrokenStable=allScoringBrokenStable,
        noKingdom=Pair.choose(dialog({'qa_pair_attack','qa_pair_slash'}, {}))==nil,
        malformed=Pair.choose({component={name='ChooseInitialGeneralBox',model={
          name='ChooseInitialGeneralModel',prop={hegemony=true,choiceNum=2}}}})==nil}
    `);
    assert.equal(report.dualA, true);
    assert.equal(report.dualB, true);
    assert.equal(report.dualInvalid, false);
    assert.equal(report.wildMain, true);
    assert.equal(report.wildDeputy, false);
    assert.equal(report.disabledKingdom, true);
    assert.ok(report.slotMain > report.slotDeputy, 'MainPlace-only skill must count only on main');
    assert.ok(report.deputyDeputy > report.deputyMain, 'DeputyPlace-only skill must count only on deputy');
    assert.ok(report.companion > report.withoutCompanion, 'CompanionEffect must be valued');
    assert.equal(report.stableOrder, true);
    assert.equal(report.stableDuplicate, true);
    assert.equal(report.tieStable, true);
    assert.equal(report.unknownFinite, true);
    assert.ok(Math.abs(report.duplicatePower - 1.1) < 1e-8,
      'identical skills on both generals must contribute power only once');
    assert.equal(report.duplicateSynergy, 0,
      'a duplicated skill cannot create cross-general synergy with itself');
    assert.equal(report.incompleteFallback, true,
      'missing general scoring data must fall back to a server-law-legal pair');
    assert.equal(report.scorablePreferred, true,
      'a complete scored pair should outrank incomplete fallback choices');
    assert.equal(report.allScoringBrokenLegal, true,
      'every scoring failure must still return a legal server-law pair');
    assert.equal(report.allScoringBrokenStable, true,
      'fallback tie-break must remain deterministic when all scores are -infinity');
    assert.equal(report.noKingdom, true);
    assert.equal(report.malformed, true);
  } finally { runtime.close(); }
});

test('deterministic baseline comparison over diverse offered rosters', async (context) => {
  const runtime = new LuaRuntime({files: packageFiles(), callbacks: {send() {}, ui() {}, setup() {}, log() {}}});
  await runtime.start();
  try {
    const result = runtime.eval<{
      trials: number; valid: number; baselineValid: number;
      improved: number; tied: number; worse: number; meanScore: number;
      baselineMean: number; distribution: Record<string, number>;
      baselineDistribution: Record<string, number>; swappedDifferent: number;
      elapsedMs: number;
    }>(`${fixture}
      local valid, baseValid, improved, tied, worse, sum, baseSum, swaps = 0,0,0,0,0,0,0,0
      local dist, baseDist = {}, {}
      local start=os.clock()
      for seed=1,240 do
        -- Reproducible roster rotation and seat order; avoid math.random global state.
        local roster={}
        local offset=(seed * 7) % #all
        for i=1,8 do roster[i]=all[(offset + i + math.floor(seed/9)) % #all + 1] end
        local data=dialog(roster)
        local best=Pair.choose(data)
        local baseline
        for _,a in ipairs(roster) do
          for _,b in ipairs(roster) do
            local k=Fk:getKingdomInHegemony(a,b,{'wei','shu'})
            if a~=b and Fk:canMatchInHegemony(a,b,{'wei','shu'}) and #k>0 then
              baseline={a..','..b,'kingdom,'..k[1]}; break
            end
          end
          if baseline then break end
        end
        if baseline then
          if Pair.validate(data,baseline) then baseValid=baseValid+1 end
          if Pair.validate(data,best) then valid=valid+1 end
          local a,b=best[1]:match('^([^,]+),([^,]+)$')
          local x,y=baseline[1]:match('^([^,]+),([^,]+)$')
          local score=Pair.score(a,b)
          local baseScore=Pair.score(x,y)
          sum=sum+score; baseSum=baseSum+baseScore
          if score>baseScore+1e-8 then improved=improved+1
          elseif score<baseScore-1e-8 then worse=worse+1
          else tied=tied+1 end
          dist[best[1]]=(dist[best[1]] or 0)+1
          baseDist[baseline[1]]=(baseDist[baseline[1]] or 0)+1
          for _,first in ipairs(roster) do
            for _,second in ipairs(roster) do
              if first~=second and Fk:canMatchInHegemony(first,second,{'wei','shu'}) and
                  Fk:canMatchInHegemony(second,first,{'wei','shu'}) and
                  #Fk:getKingdomInHegemony(first,second,{'wei','shu'})>0 and
                  #Fk:getKingdomInHegemony(second,first,{'wei','shu'})>0 and
                  math.abs(Pair.score(first,second)-Pair.score(second,first))>1e-8 then
                swaps=swaps+1; break
              end
            end
          end
        end
      end
      return {trials=240,valid=valid,baselineValid=baseValid, improved=improved,
        tied=tied,worse=worse,meanScore=sum/240,baselineMean=baseSum/240,
        distribution=dist,baselineDistribution=baseDist,swappedDifferent=swaps,
        elapsedMs=(os.clock()-start)*1000}
    `);
    context.diagnostic(JSON.stringify(result));
    assert.equal(result.trials, result.baselineValid);
    assert.equal(result.trials, result.valid);
    assert.equal(result.worse, 0, 'exhaustive search cannot score below baseline');
    assert.ok(result.improved > 0);
    assert.ok(result.swappedDifferent > 0);
    assert.ok(result.meanScore > result.baselineMean);
  } finally { runtime.close(); }
});

test('pinned 14-package Hegemony corpus: legal pair, server-order baseline, slot value and bounded CPU cost', async (context) => {
  // The pinned source loads the published general/skill definitions, while
  // this single module is overridden with the local candidate being tested.
  const files = loadUpstreamFiles(path.resolve(process.cwd(), '../../scratch/upstream'), UPSTREAM_PACKAGE_NAMES);
  files.set('packages/freekill-core/ltk/server/ai/general_pair.lua',
    fs.readFileSync(path.resolve(process.cwd(), '../../runtime/packages/freekill-core/ltk/server/ai/general_pair.lua')));
  const runtime = new LuaRuntime({files, callbacks: {send() {}, ui() {}, setup() {}, log() {}}});
  await runtime.start();
  try {
    const report = runtime.eval<{
      activeGenerals: number; modeledSkills: number; unmodeledSkills: number;
      modeledOccurrences: number; allOccurrences: number;
      trials: number; soluble: number; candidateValid: number; baselineValid: number;
      higher: number; equal: number; lower: number;
      candidateMean: number; baselineMean: number;
      distinctCandidate: number; distinctBaseline: number;
      topCandidateCounts: number[]; topBaselineCounts: number[];
      orderedCompared: number; orderedDifferent: number;
      sensitivityChanges: number; sensitivityScoreChanges: number;
      profileSelectionChanges: number; profileScoreChanges: number;
      elapsedMs: number; worstMs: number;
    }>(String.raw`
      FileIO.cd('packages/freekill-core')
      local Pair = require('ltk.server.ai.general_pair')
      FileIO.cd('../..')
      local disabled = Fk.game_mode_disabled['new_heg_mode'] or Util.DummyTable
      local pool, seenSkills = {}, {}
      for name, general in pairs(Fk.generals) do
        local pack = general.package
        if pack and not table.contains(disabled, pack.name) and
            not general.hidden and not general.total_hidden and
            type(general.maxHp)=='number' and type(general.getSkillNameList)=='function' then
          pool[#pool+1] = name
          for _, skill in ipairs(general:getSkillNameList(true)) do
            seenSkills[skill]=(seenSkills[skill] or 0)+1
          end
        end
      end
      table.sort(pool)
      local modeled,unmodeled,modeledOccurrences,allOccurrences=0,0,0,0
      for skill, count in pairs(seenSkills) do
        allOccurrences=allOccurrences+count
        if Pair.skills[skill] then
          modeled=modeled+1; modeledOccurrences=modeledOccurrences+count
        else
          unmodeled=unmodeled+1
        end
      end
      local enabled = {'wei','shu','wu','qun','jin','wild'}
      local function offer(roster)
        return {component={name='ChooseInitialGeneralBox', model={
          name='ChooseInitialGeneralModel', prop={
            hegemony=true,choiceNum=2,generals=roster,enabledKingdoms=enabled
          }}}}
      end
      local kingdomOrder = {wei=1,shu=2,wu=3,qun=4,jin=5,wild=6}
      local function serverOrder(roster)
        -- Room groups by kingdom; each group preserves the offered order.
        local groups,ordered={},{}
        for _,g in ipairs(roster) do
          local rank=kingdomOrder[Fk.generals[g].kingdom] or 7
          groups[rank]=groups[rank] or {}
          groups[rank][#groups[rank]+1]=g
        end
        for rank=1,7 do
          for _,g in ipairs(groups[rank] or {}) do ordered[#ordered+1]=g end
        end
        return ordered
      end
      local function firstMatch(roster)
        -- The server picks the first canMatchInHegemony pair and provides an
        -- empty kingdom field; here an allowed kingdom is selected for QA.
        for _,a in ipairs(roster) do
          for _,b in ipairs(roster) do
            if Fk:canMatchInHegemony(a,b,enabled) then
              local kingdoms=Fk:getKingdomInHegemony(a,b,enabled)
              return {a..','..b, 'kingdom,'..(kingdoms[1] or '')}
            end
          end
        end
      end
      local function key(reply) return reply and reply[1] or '' end
      local function distinctCounts(counts)
        local values={}
        for _,n in pairs(counts) do values[#values+1]=n end
        table.sort(values,function(a,b) return a>b end)
        return #values,{table.unpack(values,1,math.min(5,#values))}
      end
      local rng=26071986
      local function rand(n)
        rng=(rng*48271)%2147483647
        return rng%n+1
      end
      local trials,soluble,valid,baseValid,higher,equal,lower=320,0,0,0,0,0,0
      local scoreSum,baseSum,ordered,changed,configChanged,configScoreChanged=0,0,0,0,0,0
      local profileSelectionChanges,profileScoreChanges=0,0
      local addedProfiles={'duanbing','ld__tunjiang','qixi','shangyi',
        'shoucheng','tianyi','tiaoxin','yizhi'}
      local dist,baseDist={},{}
      local totalMs,worstMs=0,0
      for seed=1,trials do
        -- Sample without replacement using only public general declarations.
        local chosen,used={},{}
        while #chosen<10 do
          local g=pool[rand(#pool)]
          if not used[g] then used[g]=true; chosen[#chosen+1]=g end
        end
        local roster=serverOrder(chosen)
        local data=offer(roster)
        local started=os.clock()
        local best=Pair.choose(data)
        local ms=(os.clock()-started)*1000
        totalMs=totalMs+ms; worstMs=math.max(worstMs,ms)
        local base=firstMatch(roster)
        if best then
          soluble=soluble+1
          if Pair.validate(data,best) then valid=valid+1 end
          local a,b=best[1]:match('^([^,]+),([^,]+)$')
          local score=Pair.score(a,b)
          scoreSum=scoreSum+score
          dist[key(best)]=(dist[key(best)] or 0)+1
          if Pair.validate(data,base) then
            baseValid=baseValid+1
            local x,y=base[1]:match('^([^,]+),([^,]+)$')
            local baseScore=Pair.score(x,y)
            baseSum=baseSum+baseScore
            baseDist[key(base)]=(baseDist[key(base)] or 0)+1
            if score>baseScore+1e-8 then higher=higher+1
            elseif score<baseScore-1e-8 then lower=lower+1
            else equal=equal+1 end
          end
          local beforeWeight=Pair.weights.synergy
          Pair.weights.synergy=0
          local withoutSynergy=Pair.choose(data)
          if key(best)~=key(withoutSynergy) then configChanged=configChanged+1 end
          local changedScore=Pair.score(a,b)
          if math.abs(changedScore-score)>1e-8 then configScoreChanged=configScoreChanged+1 end
          Pair.weights.synergy=beforeWeight
          local saved={}
          for _,name in ipairs(addedProfiles) do
            saved[name]=Pair.skills[name]; Pair.skills[name]=nil
          end
          local withoutProfiles=Pair.choose(data)
          if key(best)~=key(withoutProfiles) then
            profileSelectionChanges=profileSelectionChanges+1
          end
          if math.abs(Pair.score(a,b)-score)>1e-8 then
            profileScoreChanges=profileScoreChanges+1
          end
          for _,name in ipairs(addedProfiles) do Pair.skills[name]=saved[name] end
          if Fk:canMatchInHegemony(b,a,enabled) and
              #Fk:getKingdomInHegemony(b,a,enabled)>0 then
            ordered=ordered+1
            if math.abs(Pair.score(a,b)-Pair.score(b,a))>1e-8 then changed=changed+1 end
          end
        end
      end
      local n,top=distinctCounts(dist)
      local bn,btop=distinctCounts(baseDist)
      return {activeGenerals=#pool,modeledSkills=modeled,unmodeledSkills=unmodeled,
        modeledOccurrences=modeledOccurrences,allOccurrences=allOccurrences,
        trials=trials,soluble=soluble,candidateValid=valid,baselineValid=baseValid,
        higher=higher,equal=equal,lower=lower,
        candidateMean=soluble>0 and scoreSum/soluble or 0,
        baselineMean=baseValid>0 and baseSum/baseValid or 0,
        distinctCandidate=n,distinctBaseline=bn,topCandidateCounts=top,topBaselineCounts=btop,
        orderedCompared=ordered,orderedDifferent=changed,
        sensitivityChanges=configChanged,sensitivityScoreChanges=configScoreChanged,
        profileSelectionChanges=profileSelectionChanges,
        profileScoreChanges=profileScoreChanges,
        elapsedMs=totalMs,worstMs=worstMs}
    `);
    context.diagnostic(JSON.stringify(report));
    assert.ok(report.activeGenerals >= 200, 'must use a substantial real Hegemony pool');
    assert.ok(report.unmodeledSkills > 0, 'unknown skills must be represented in corpus');
    assert.ok(report.modeledOccurrences / report.allOccurrences >= 0.05,
      'modeled skill coverage must reach the declared initial corpus threshold');
    assert.ok(report.soluble > 0);
    assert.equal(report.candidateValid, report.soluble, 'every soluble offer must pass server-law validator');
    assert.equal(report.baselineValid, report.soluble, 'baseline comparison requires a legal server-default choice');
    assert.equal(report.lower, 0);
    assert.equal(report.higher + report.equal, report.baselineValid);
    assert.ok(report.orderedCompared > 0, 'real ordered pairs must be represented');
    assert.ok(report.orderedDifferent > 0, 'real main/deputy changes must be observed');
    assert.ok(report.profileScoreChanges > 0,
      'new evidence-backed profiles must affect the score on real offers');
  } finally { runtime.close(); }
});
