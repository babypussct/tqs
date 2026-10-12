/** Reprocess historical public DOM text without modifying live evidence. */
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { localizedGameLog } from '../src/engine/displayText';

const [output, ...inputs] = process.argv.slice(2);
assert.ok(output && inputs.length, 'Usage: tsx scripts/audit-display-text.ts output.json evidence.json ...');
assert.ok(!existsSync(output), 'Refusing to overwrite an existing audit');
assert.ok(!inputs.some((input) => path.resolve(input) === path.resolve(output)));
const suspect = /&#(?:x[0-9a-f]+|\d+);|(?:[a-z]+__)[a-z_]+|#[A-Za-z_]+|[\u3400-\u9fff]/iu;
const targetCancelledSources = [
  'Vương Duyệt/Tướng ẩn 使用的 Hỏa Sát[♥4] 取消了目标 Tướng ẩn/Mã Đại (bạn)',
  'Vương Duyệt/Lưu Phu Nhân 使用的 Hỏa Sát[♦4] 取消了目标 Phùng Tập/Mã Đại (bạn)',
];
const observed = new Set<string>();
const reports = inputs.map((input) => {
  const bytes = readFileSync(input);
  const evidence = JSON.parse(bytes.toString()) as { gameOver: boolean; visibleText: string[]; unresolved: string[] };
  assert.equal(evidence.gameOver, true, 'Historical evidence must include real GameOver');
  assert.ok(Array.isArray(evidence.visibleText) && evidence.visibleText.every((text) => typeof text === 'string'));
  const changes = evidence.visibleText.flatMap((before) => {
    observed.add(before);
    const after = localizedGameLog(before);
    return after === before ? [] : [{ before, after }];
  });
  const unresolved = evidence.visibleText.map(localizedGameLog).filter((text) => suspect.test(text));
  return {
    input: path.resolve(input), inputSha256: createHash('sha256').update(bytes).digest('hex'),
    samples: evidence.visibleText.length, originalUnresolved: evidence.unresolved.length,
    changed: changes.length, unresolved, changes,
  };
});
const targetCancelled = targetCancelledSources.map((source) => {
  assert.ok(observed.has(source), 'Missing the expected historical TargetCancelled source');
  const translated = localizedGameLog(source);
  assert.ok(translated.startsWith('Mục tiêu ') && translated.includes('đã bị hủy khỏi lá ') && !suspect.test(translated));
  return { source, translated };
});
const report = {
  createdAt: new Date().toISOString(),
  scope: 'Reprocessing historical public DOM text only; this is not a new live observation or a complete semantic review.',
  totalSamples: reports.reduce((total, item) => total + item.samples, 0),
  unresolved: reports.reduce((total, item) => total + item.unresolved.length, 0),
  targetCancelled, reports,
};
mkdirSync(path.dirname(path.resolve(output)), { recursive: true });
writeFileSync(output, JSON.stringify(report, null, 2) + '\n', { flag: 'wx' });
console.log(JSON.stringify({ output: path.resolve(output), totalSamples: report.totalSamples,
  unresolved: report.unresolved, files: reports.map(({ samples, changed, unresolved }) => ({ samples, changed, unresolved: unresolved.length })) }));
assert.equal(report.unresolved, 0, 'Some historical display text still needs review');
