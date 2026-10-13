/**
 * Fail-closed inventory gate for Lua native request callers.
 *
 * This is intentionally narrower than a live rules test: it proves that the
 * candidate runtime has known request callsites and that every request family
 * is wired to a production renderer plus a local regression fixture. It does
 * not claim that every rule has been exercised on a real C++ server.
 */
import assert from 'node:assert/strict';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = fileURLToPath(new URL('../../../', import.meta.url));
const runtimeRoot = path.resolve(process.env.TQS_NATIVE_RUNTIME_ROOT ??
  path.join(repoRoot, 'runtime'));
const packagesRoot = path.join(runtimeRoot, 'packages');
const sourceRoot = path.join(repoRoot, 'game/web');

type SourceRule = { file: string; patterns: readonly string[] };
type CallerContract = {
  method: string;
  command: string;
  minMatches: number;
  source: readonly SourceRule[];
  fixtures: readonly SourceRule[];
};

const definitions = new Set([
  'freekill-core/ltk/server/room.lua',
  'freekill-core/ltk/client/client.lua',
]);

const contracts: readonly CallerContract[] = [
  {
    method: 'askToChoice', command: 'AskForChoices', minMatches: 1,
    source: [
      { file: 'src/engine/connection.ts', patterns: ['AskForChoices', 'choicePrompt'] },
      { file: 'src/App.tsx', patterns: ['ChoicePanel', 'AskForChoices'] },
    ],
    fixtures: [{ file: 'scripts/choices.test.ts', patterns: ['AskForChoices'] }],
  },
  {
    method: 'askToChoices', command: 'AskForChoices', minMatches: 1,
    source: [
      { file: 'src/engine/connection.ts', patterns: ['AskForChoices', 'choicePrompt'] },
      { file: 'src/App.tsx', patterns: ['ChoicePanel', 'AskForChoices'] },
    ],
    fixtures: [{ file: 'scripts/real-lua-e2e/run.ts', patterns: ['beginChoices', 'Xác nhận lựa chọn'] }],
  },
  {
    method: 'askToChooseCard', command: 'AskForCardChosen', minMatches: 1,
    source: [
      { file: 'src/engine/cardSelection.ts', patterns: ['AskForCardChosen', 'parseCardSelection'] },
      { file: 'src/App.tsx', patterns: ['CardSelectionPanel', 'cardSelectionPrompt'] },
    ],
    fixtures: [{ file: 'scripts/card-selection.test.ts', patterns: ['AskForCardChosen', 'parseCardSelection'] }],
  },
  {
    method: 'askToChooseCards', command: 'AskForPoxi', minMatches: 1,
    source: [
      { file: 'src/engine/cardSelection.ts', patterns: ['AskForPoxi', 'parseCardSelection'] },
      { file: 'src/App.tsx', patterns: ['CardSelectionPanel', 'cardSelectionPrompt'] },
    ],
    fixtures: [{ file: 'scripts/card-selection.test.ts', patterns: ['AskForPoxi', 'parseCardSelection'] }],
  },
  {
    method: 'askToChooseCardsAndChoice', command: 'AskForCardsAndChoice', minMatches: 1,
    source: [
      { file: 'src/engine/cardsAndChoice.ts', patterns: ['parseCardsAndChoice'] },
      { file: 'src/engine/connection.ts', patterns: ['AskForCardsAndChoice', 'parseCardsAndChoice'] },
      { file: 'src/App.tsx', patterns: ['CardsAndChoicePanel', 'cardsAndChoicePrompt'] },
    ],
    fixtures: [{ file: 'scripts/cards-and-choice.test.ts', patterns: ['AskForCardsAndChoice'] }],
  },
  {
    method: 'askToChooseCardsAndPlayers', command: 'AskForUseActiveSkill', minMatches: 1,
    source: [
      { file: 'src/store/gameplayState.ts', patterns: ['AskForUseActiveSkill', 'GAMEPLAY_REQUESTS'] },
      { file: 'src/GameplayControls.tsx', patterns: ['SkillButton', 'Interaction'] },
      { file: 'src/engine/connection.ts', patterns: ['updateRequestUI', 'GAMEPLAY_REQUESTS'] },
    ],
    fixtures: [
      { file: 'scripts/gameplay.test.ts', patterns: ['SkillButton', 'Interaction'] },
      { file: 'scripts/real-lua-e2e/run.ts', patterns: ['gameplay()', 'gameplay-choice'] },
    ],
  },
  {
    method: 'askToUseActiveSkill', command: 'AskForUseActiveSkill', minMatches: 1,
    source: [
      { file: 'src/store/gameplayState.ts', patterns: ['AskForUseActiveSkill', 'GAMEPLAY_REQUESTS'] },
      { file: 'src/GameplayControls.tsx', patterns: ['SkillButton', 'SpecialSkills'] },
      { file: 'src/engine/connection.ts', patterns: ['updateRequestUI', 'GAMEPLAY_REQUESTS'] },
    ],
    fixtures: [
      { file: 'scripts/gameplay.test.ts', patterns: ['SkillButton', 'UpdateRequestUI'] },
      { file: 'scripts/real-lua-e2e/run.ts', patterns: ['gameplay()', 'gameplay-choice'] },
    ],
  },
  {
    method: 'askToUseCard', command: 'AskForUseCard', minMatches: 1,
    source: [
      { file: 'src/store/gameplayState.ts', patterns: ['AskForUseCard', 'GAMEPLAY_REQUESTS'] },
      { file: 'src/GameBoardScreen.tsx', patterns: ['GameplayControls', 'pendingRequest'] },
      { file: 'src/engine/connection.ts', patterns: ['updateRequestUI', 'GAMEPLAY_REQUESTS'] },
    ],
    fixtures: [{ file: 'scripts/gameplay.test.ts', patterns: ['AskForUseCard', 'PlayCard'] }],
  },
  {
    method: 'askForResponse', command: 'AskForResponseCard', minMatches: 1,
    source: [
      { file: 'src/store/gameplayState.ts', patterns: ['AskForResponseCard', 'GAMEPLAY_REQUESTS'] },
      { file: 'src/engine/hostLua.ts', patterns: ['AskForResponseCard', 'UpdateRequestUI'] },
      { file: 'src/GameBoardScreen.tsx', patterns: ['GameplayControls', 'pendingRequest'] },
    ],
    fixtures: [{ file: 'scripts/real-lua-e2e/harness.tsx', patterns: ['beginResponseCard', 'AskForResponseCard'] }],
  },
  {
    method: 'askToChooseToMoveCardInBoard', command: 'AskForMoveCardInBoard', minMatches: 1,
    source: [
      { file: 'src/engine/nativeDialogs.ts', patterns: ['AskForMoveCardInBoard', "kind='boardMove'"] },
      { file: 'src/App.tsx', patterns: ['NativeDialogPanel', 'nativeDialogPrompt'] },
    ],
    fixtures: [{ file: 'scripts/real-lua-e2e/harness.tsx', patterns: ['AskForMoveCardInBoard', 'boardMove'] }],
  },
  {
    method: 'askToArrangeCards', command: 'AskForArrangeCards', minMatches: 1,
    source: [
      { file: 'src/engine/nativeDialogs.ts', patterns: ['AskForArrangeCards', "kind = 'arrange'"] },
      { file: 'src/NativeDialogPanel.tsx', patterns: ["prompt.kind === 'arrange'"] },
      { file: 'src/engine/connection.ts', patterns: ['AskForArrangeCards', 'movedRows'] },
    ],
    fixtures: [{ file: 'scripts/native-dialogs.test.ts', patterns: ['AskForArrangeCards', 'movedRows'] }],
  },
  {
    method: 'askToAG', command: 'AskForAG', minMatches: 1,
    source: [
      { file: 'src/engine/nativeDialogs.ts', patterns: ['AskForAG', "kind = 'ag'"] },
      { file: 'src/NativeDialogPanel.tsx', patterns: ['ag', 'respond'] },
    ],
    fixtures: [{ file: 'scripts/native-dialogs.test.ts', patterns: ['AskForAG', 'parseNativeDialog'] }],
  },
  {
    method: 'askToCustomDialog', command: 'CustomDialog', minMatches: 1,
    source: [
      { file: 'src/engine/nativeDialogs.ts', patterns: ['CustomDialog', 'KnownBothBox.qml'] },
      { file: 'src/App.tsx', patterns: ['NativeDialogPanel', 'CustomDialog'] },
    ],
    fixtures: [{ file: 'scripts/native-dialogs.test.ts', patterns: ['CustomDialog', 'parseNativeDialog'] }],
  },
  {
    method: 'askToChooseSkills', command: 'CustomDialog', minMatches: 1,
    source: [
      { file: 'src/engine/nativeDialogs.ts', patterns: ['ChooseSkillBox.qml', 'ChooseSkillModel.qml'] },
      { file: 'src/NativeDialogPanel.tsx', patterns: ['skills', 'respond'] },
    ],
    fixtures: [{ file: 'scripts/native-dialogs.test.ts', patterns: ['ChooseSkillBox.qml', 'ChooseSkill'] }],
  },
  {
    method: 'askToChooseGeneralsAndChoice', command: 'CustomDialog', minMatches: 1,
    source: [
      { file: 'src/engine/nativeDialogs.ts', patterns: ['ChooseGeneralsAndChoiceBox.qml', 'generalsAndChoice'] },
      { file: 'src/NativeDialogPanel.tsx', patterns: ['generalsAndChoice', 'respond'] },
    ],
    fixtures: [{ file: 'scripts/real-lua-e2e/run.ts', patterns: ['ChooseGeneralsAndChoice', 'native cards/choice'] }],
  },
  {
    method: 'askForChooseCardNames', command: 'CustomDialog', minMatches: 1,
    source: [
      { file: 'src/engine/nativeDialogs.ts', patterns: ['ChooseCardNamesBox.qml', 'cardNames'] },
      { file: 'src/NativeDialogPanel.tsx', patterns: ['cardNames', 'respond'] },
    ],
    fixtures: [{ file: 'scripts/real-lua-e2e/run.ts', patterns: ['ChooseCardNames', 'native single-choice'] }],
  },
  {
    method: 'askForSkillInvoke', command: 'AskForSkillInvoke', minMatches: 1,
    source: [
      { file: 'src/engine/skillInvoke.ts', patterns: ['parseSkillInvokePrompt', 'AskForSkillInvoke'] },
      { file: 'src/App.tsx', patterns: ['SkillInvokePanel', 'AskForSkillInvoke'] },
      { file: 'src/engine/connection.ts', patterns: ['AskForSkillInvoke', 'respondToSkillInvoke'] },
    ],
    fixtures: [{ file: 'scripts/connection.test.ts', patterns: ['AskForSkillInvoke', 'optional native skill prompts'] }],
  },
];

function walk(dir: string): string[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return walk(full);
    return entry.isFile() && entry.name.endsWith('.lua') ? [full] : [];
  });
}

function relative(file: string): string {
  return path.relative(packagesRoot, file).split(path.sep).join('/');
}

function readSource(file: string): string {
  const full = path.join(sourceRoot, file);
  assert.ok(statSync(full, { throwIfNoEntry: false })?.isFile(), `Missing source contract file: ${full}`);
  return readFileSync(full, 'utf8');
}

function hasPatterns(file: string, patterns: readonly string[]): boolean {
  const source = readSource(file);
  return patterns.every((pattern) => source.includes(pattern));
}

assert.ok(statSync(packagesRoot, { throwIfNoEntry: false })?.isDirectory(),
  `Missing candidate runtime packages: ${packagesRoot}`);

const files = walk(packagesRoot).filter((file) => !definitions.has(relative(file)));
const callerRows = contracts.map((contract) => {
  const pattern = new RegExp(`\\b${contract.method}\\s*\\(`, 'u');
  const matches = files.flatMap((file) => readFileSync(file, 'utf8').split(/\r?\n/u)
    .map((line, lineIndex) => pattern.test(line) ? { file: relative(file), line: lineIndex + 1 } : null)
    .filter((match): match is { file: string; line: number } => match !== null));
  const sourcePass = contract.source.every((rule) => hasPatterns(rule.file, rule.patterns));
  const fixturePass = contract.fixtures.every((rule) => hasPatterns(rule.file, rule.patterns));
  assert.ok(matches.length >= contract.minMatches,
    `${contract.method} has ${matches.length} runtime callsites; expected at least ${contract.minMatches}`);
  assert.ok(sourcePass, `${contract.method} -> ${contract.command} has an incomplete production mapping`);
  assert.ok(fixturePass, `${contract.method} -> ${contract.command} has an incomplete local fixture mapping`);
  return {
    method: contract.method, command: contract.command,
    allMatches: matches.length,
    files: [...new Set(matches.map((match) => match.file))].sort(),
  };
});

console.log(`Native caller audit: ${files.length} Lua files, ${contracts.length} request families`);
for (const row of callerRows)
  console.log(`PASS ${row.method} -> ${row.command}: ${row.allMatches} runtime callsite(s)`);
console.log('PASS native caller production mappings and local fixture mappings');
