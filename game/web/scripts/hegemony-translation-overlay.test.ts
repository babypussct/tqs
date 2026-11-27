import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { VI_HEGEMONY_UPDATES } from '../src/engine/vietnameseHegemonyUpdates';
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

test('Hegemony description delta matches the current source shapes and wins runtime precedence', () => {
  const { descriptions } = JSON.parse(fs.readFileSync(
    path.join(repositoryRoot, 'docs/translations/HEGEMONY_DESCRIPTION_DELTA_20261127.json'), 'utf8',
  )) as { descriptions: Record<string, { old: { zh: string } | null; pin: { zh: string } | null; head: { zh: string } }> };
  const keys = Object.keys(descriptions);
  assert.equal(keys.length, 87);
  assert.equal(Object.values(descriptions).filter(row => row.old).length, 41);
  assert.equal(Object.values(descriptions).filter(row => row.pin && !row.old).length, 42);
  assert.equal(Object.values(descriptions).filter(row => !row.pin).length, 4);
  assert.deepEqual(Object.keys(VI_HEGEMONY_UPDATES).filter(key => key.startsWith(':')).sort(), keys.sort());
  for (const [key, row] of Object.entries(descriptions)) {
    const translation = VI_HEGEMONY_UPDATES[key];
    assert.ok(translation, key);
    assert.equal(VI_ADDITIONS[key], translation, key);
    assert.doesNotMatch(plainText(translation), /[\u3400-\u9fff]/, key);
    assert.equal(plainText(displayText(key, VI_ADDITIONS)), plainText(translation), key);
    const source = row.head.zh;
    assert.deepEqual((translation.match(placeholders) ?? []).sort(), (source.match(placeholders) ?? []).sort(), key);
    assert.deepEqual((translation.match(tags) ?? []).map(tagName).sort(), (source.match(tags) ?? []).map(tagName).sort(), key);
    const name = VI_ADDITIONS[key.slice(1)];
    assert.ok(name, key);
    assert.doesNotMatch(name, /[\u3400-\u9fff]/, key);
  }
  for (const key of keys.filter(key => key.startsWith(':nos_heg__'))) {
    const skill = key.slice(':nos_heg__'.length);
    const modern = VI_ADDITIONS[':ld__' + skill] ?? VI_ADDITIONS[':' + skill];
    assert.ok(modern, key);
    assert.notEqual(VI_ADDITIONS[key], modern, key);
  }
});


test('modern and historical Thành Lược resolve their own prompts', () => {
  assert.match(VI_ADDITIONS['#ld__chenglue'], /Hỏa Công/);
  assert.match(VI_ADDITIONS['#nos_heg__chenglue-draw'], /%dest/);
  assert.match(VI_ADDITIONS['#nos_heg__chenglue-mark'], /Âm Dương Ngư/);
  for (const key of ['#ld__chenglue', '#nos_heg__chenglue-draw', '#nos_heg__chenglue-mark']) {
    assert.equal(VI_ADDITIONS[key], VI_HEGEMONY_UPDATES[key]);
  }
});

test('modern Ký Ly presents both choices with the card placeholder', () => {
  assert.match(VI_ADDITIONS['#ld__jilix-choice'], /%arg/);
  assert.match(VI_ADDITIONS.ld__jilix_effect, /thêm một lần/);
  assert.match(VI_ADDITIONS.ld__jilix_remove, /Loại bỏ tướng/);
  for (const key of ['#ld__jilix-choice', 'ld__jilix_effect', 'ld__jilix_remove']) {
    assert.equal(VI_ADDITIONS[key], VI_HEGEMONY_UPDATES[key]);
  }
});
