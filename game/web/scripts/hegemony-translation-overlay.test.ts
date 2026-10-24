import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { VI_ADDITIONS } from '../src/engine/vietnamese';
import { displayText, plainText } from '../src/engine/displayText';
import { VI_HEGEMONY_TRANSLATIONS } from '../src/engine/vietnameseHegemony';
import { VI_HEGEMONY_P0_SUPPLEMENT } from '../src/engine/vietnameseHegemonyP0Supplement';
import { VI_HEGEMONY_P1_SUPPLEMENT } from '../src/engine/vietnameseHegemonyP1Supplement';
import { VI_HEGEMONY_P2_SUPPLEMENT } from '../src/engine/vietnameseHegemonyP2Supplement';

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const queuePath = path.join(repositoryRoot, 'docs/translations/HEGEMONY_VIETNAMESE_WORK_QUEUE.csv');

function parseCsv(input: string): Record<string, string>[] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = '';
  let quoted = false;
  for (let index = 0; index < input.length; index += 1) {
    const character = input[index];
    if (quoted) {
      if (character === '"' && input[index + 1] === '"') {
        field += '"';
        index += 1;
      } else if (character === '"') {
        quoted = false;
      } else {
        field += character;
      }
    } else if (character === '"') {
      quoted = true;
    } else if (character === ',') {
      row.push(field);
      field = '';
    } else if (character === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else if (character !== '\r') {
      field += character;
    }
  }
  if (field !== '' || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  const headers = rows.shift() ?? [];
  return rows.map((values) => Object.fromEntries(headers.map((header, index) => [header, values[index] ?? ''])));
}

const placeholders = /%(?:arg\d*|src|dest|from|to)\b/g;
const tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi;
const tagName = (tag: string) => tag.replace(/<\/?|\s.*|>/g, '').replace(/\/$/, '').toLowerCase();

test('Hegemony overlay resolves the accounted queue without changing source shape', () => {
  const rows = parseCsv(fs.readFileSync(queuePath, 'utf8').replace(/^\uFEFF/, ''));
  assert.equal(rows.length, 4_843);
  assert.equal(new Set(rows.map((row) => row.key)).size, 4_843);

  const queueByKey = new Map(rows.map((row) => [row.key, row]));
  const translatedRows = rows.filter((row) => row.proposed_vi !== '');
  assert.equal(translatedRows.length, 3_941);
  assert.deepEqual(
    rows.filter((row) => row.proposed_vi === '' && row.review === ''),
    [],
    'every queue row must be translated or explicitly classified',
  );

  const runtimeTranslations = {
    ...VI_HEGEMONY_TRANSLATIONS,
    ...VI_HEGEMONY_P0_SUPPLEMENT,
    ...VI_HEGEMONY_P1_SUPPLEMENT,
    ...VI_HEGEMONY_P2_SUPPLEMENT,
  };
  for (const row of translatedRows) {
    assert.ok(runtimeTranslations[row.key], `${row.key} is proposed but absent from runtime overlays`);
  }
  for (const [key, translation] of Object.entries(runtimeTranslations)) {
    assert.doesNotMatch(plainText(translation), /[\u3400-\u9fff]/, `${key} still contains CJK`);
    const rendered = plainText(displayText(key, VI_ADDITIONS));
    assert.notEqual(rendered, key, `${key} did not resolve in displayText`);

    const row = queueByKey.get(key);
    if (!row) continue; // Direct aliases can be useful to runtime without a static queue row.
    assert.equal(row.proposed_vi, translation, `${key} is out of sync with the queue`);
    if (!row.zh_CN) continue;
    assert.deepEqual(
      [...(row.zh_CN.match(placeholders) ?? [])].sort(),
      [...(translation.match(placeholders) ?? [])].sort(),
      `${key} changed a placeholder`,
    );
    assert.deepEqual(
      [...(row.zh_CN.match(tags) ?? [])].map(tagName).sort(),
      [...(translation.match(tags) ?? [])].map(tagName).sort(),
      `${key} changed rich-text tag shape`,
    );
  }
});
