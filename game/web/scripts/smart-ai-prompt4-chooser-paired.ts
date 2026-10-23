/**
 * Replays the same bounded chooser input against the pinned pre-fix source
 * and the current strategy Lua. This is Wasmoon decision-surface evidence,
 * not a native C++ matched request or a gameplay/win-rate measurement.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';

const scripts = path.dirname(fileURLToPath(import.meta.url));
const packageRoot = path.resolve(scripts, '../../../runtime/packages');
const names = ['choose_players_skill.lua', 'choose_cards_skill.lua', 'ex__choose_skill.lua'];
const sourceRevision = 'b8527d28';
const pattern = /\.(?:lua|json|md|qml|js)$/iu;

function runtimeFiles(baseline: boolean): Map<string, Uint8Array> {
  const files = new Map<string, Uint8Array>();
  function visit(dir: string) {
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
      if (item.name === '.git') continue;
      const absolute = path.join(dir, item.name);
      if (item.isDirectory()) visit(absolute);
      else if (item.isFile() && pattern.test(item.name)) {
        const key = `packages/${path.relative(packageRoot, absolute).split(path.sep).join('/')}`;
        files.set(key, fs.readFileSync(absolute));
      }
    }
  }
  visit(packageRoot);
  if (baseline) for (const name of names) files.set(
    `packages/freekill-core/standard/aux_skills_dir/${name}`,
    fs.readFileSync(path.join(scripts, 'fixtures/prompt4-prefixed', name)),
  );
  return files;
}

// Each fixture creates fresh selection state with a single permitted card and
// target. Both branches receive byte-identical command data and fake dashboard
// semantics. Only public labels and the legal/fallback classification escape.
const FIXTURES = String.raw`
  FileIO.cd('packages/freekill-core')
  dofile('ltk/server/ai/init.lua')
  FileIO.cd('../..')

  local AI = Fk.Ltk.AI
  local enemy = { id = 2 }
  local disabledTarget = { id = 3 }
  local names = {
    { 'players_empty', 'choose_players_skill', 'empty' },
    { 'players_card_required', 'choose_players_skill', 'card_required' },
    { 'players_disabled_target', 'choose_players_skill', 'disabled_target' },
    { 'cards_empty', 'choose_cards_skill', 'empty' },
    { 'cards_invalid', 'choose_cards_skill', 'invalid' },
    { 'cards_duplicate', 'choose_cards_skill', 'duplicate_cards' },
    { 'cards_valid', 'choose_cards_skill', 'valid' },
    { 'combined_empty', 'ex__choose_skill', 'empty' },
    { 'combined_card_required', 'ex__choose_skill', 'card_required' },
    { 'combined_disabled_target', 'ex__choose_skill', 'disabled_target' },
    { 'combined_duplicate_targets', 'ex__choose_skill', 'duplicate_targets' },
    { 'combined_valid', 'ex__choose_skill', 'valid' },
  }
  local results = {}

  for _, spec in ipairs(names) do
    local name, skill, mode = spec[1], spec[2], spec[3]
    local selectedCards, selectedTargets = {}, {}
    local data = {
      skill, 'bounded QA', mode == 'empty',
      { skillName = 'qa_missing', pattern = skill == 'choose_players_skill' and
          (mode == 'card_required' and '.' or '') or '', num = 1, min_num = 1,
        min_c_num = 1, max_c_num = 1, min_t_num = 1, max_t_num = 1,
      },
    }
    local chooser = {
      chooseCards = function()
        if mode == 'empty' then return {}, 0 end
        if mode == 'invalid' then return { 999 }, 1 end
        if mode == 'duplicate_cards' then return { 101, 101 }, 1 end
        return { 101 }, 1
      end,
      choosePlayers = function()
        if mode == 'disabled_target' then return { disabledTarget }, 1 end
        if mode == 'duplicate_targets' then return { enemy, enemy }, 1 end
        return #selectedCards > 0 and { enemy } or {}, 1
      end,
    }
    local ai = { data = data }
    function ai:findStrategyOfSkill(kind, strategyName)
      if strategyName ~= skill then return nil end
      if kind == AI.CardsStrategy and skill == 'choose_cards_skill' then return chooser end
      if kind == AI.ChoosePlayersStrategy and skill == 'choose_players_skill' then return chooser end
      if kind == AI.ChooseCardsAndPlayersStrategy and skill == 'ex__choose_skill' then return chooser end
    end
    function ai:getEnabledCards()
      return #selectedCards == 0 and { 101 } or {}
    end
    function ai:getEnabledTargets()
      return #selectedCards > 0 and #selectedTargets == 0 and { enemy } or {}
    end
    function ai:selectCard(id, enabled)
      if enabled and id == 101 and #selectedCards == 0 then selectedCards[1] = id end
    end
    function ai:selectTarget(target, enabled)
      if enabled and target == enemy and #selectedTargets == 0 then selectedTargets[1] = target end
    end
    function ai:okButtonEnabled()
      if skill == 'choose_cards_skill' then return #selectedCards == 1 end
      if skill == 'choose_players_skill' then
        return #selectedTargets == 1 and
          (data[4].pattern == '' or #selectedCards == 1)
      end
      return #selectedCards == 1 and #selectedTargets == 1
    end
    function ai:unSelectAll()
      selectedCards, selectedTargets = {}, {}
    end

    local strategy = Fk.skills[skill]:getSkeleton().ai_strategies[AI.ActiveStrategy][1]
    local ok, response = pcall(strategy.think, strategy, ai)
    if not ok then error('chooser fixture raised an exception: ' .. name) end
    local status = 'fallback'
    if response then
      local cards, targets = response[1] or {}, response[2] or {}
      -- All fixtures require one selected card. A cancelable empty reply is
      -- not a legal active-skill selection to serialize as { {}, {} }.
      local validCards = mode ~= 'invalid' and #cards == 1 and cards[1] == 101
      local validTargets = skill == 'choose_cards_skill' or
        (mode ~= 'empty' and #targets == 1 and targets[1] == enemy)
      status = validCards and validTargets and 'legal' or 'infeasible'
    end
    results[name] = status
  end
  return results
`;

async function runVariant(baseline: boolean): Promise<Record<string, 'legal' | 'fallback' | 'infeasible'>> {
  const runtime = new LuaRuntime({ files: runtimeFiles(baseline),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} } });
  await runtime.start();
  try {
    return runtime.eval(FIXTURES);
  } finally {
    runtime.close();
  }
}

export async function runPrompt4ChooserPairedFixture() {
  const baseline = await runVariant(true);
  const fixed = await runVariant(false);
  const cases = Object.fromEntries(Object.keys(baseline).sort().map((name) => [name, {
    baseline: baseline[name], fixed: fixed[name],
  }]));
  const improved = Object.values(cases).filter((entry) => entry.baseline === 'infeasible' && entry.fixed !== 'infeasible').length;
  const regressions = Object.values(cases).filter((entry) => entry.baseline !== 'infeasible' && entry.fixed === 'infeasible').length;
  return {
    schemaVersion: 1,
    kind: 'prompt4_chooser_matched_wasmoon_decision_fixture',
    baselineSource: `repository revision ${sourceRevision}; three archived pre-fix Lua adapters`,
    mode: 'new_heg_mode chooser decision semantics (isolated Wasmoon strategy)',
    cases, total: Object.keys(cases).length, fixedInfeasible: Object.values(fixed).filter((x) => x === 'infeasible').length,
    baselineInfeasible: Object.values(baseline).filter((x) => x === 'infeasible').length,
    improved, regressions,
    inputEquivalence: 'identical test script and synthetic request/dashboard semantics; fresh runtime state per variant',
    nativeRequestStateMatched: false,
    skillOpportunityDenominatorAvailable: false,
    nativeTargetQualityAvailable: false,
    winRateAvailable: false,
    limitations: [
      'This compares actual Lua chooser strategies, but the dashboard/request is a deterministic Wasmoon fixture, not a native ServerPlayer AI:makeReply request.',
      'Legal here means the fixture selection satisfies its public constraints; native feasible() and full game effects still require separate checks.',
      'No real opponent private cards, target IDs, request contents, or gameplay logs are included in the output.',
    ],
  };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const report = await runPrompt4ChooserPairedFixture();
  const encoded = `${JSON.stringify(report, null, 2)}\n`;
  if (process.argv[2]) fs.writeFileSync(process.argv[2], encoded, { mode: 0o600 });
  else process.stdout.write(encoded);
}
