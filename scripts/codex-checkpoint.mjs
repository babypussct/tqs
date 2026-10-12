#!/usr/bin/env node

// Persistent Codex handoff: refreshes only the generated Git snapshot block.
// It intentionally never reads file diffs, environment variables or secrets.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const statePath = path.join(root, 'docs/CODEX_STATE.md');
const planPath = path.join(root, 'docs/CODEX_PLAN.md');
const startMarker = '<!-- CODEX_SNAPSHOT_START -->';
const endMarker = '<!-- CODEX_SNAPSHOT_END -->';

function git(...args) {
  return execFileSync('git', args, { cwd: root, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 }).trimEnd();
}

function checkMarkers(state) {
  const first = state.indexOf(startMarker);
  const last = state.indexOf(endMarker);
  if (first < 0 || last < 0 || last < first ||
      first !== state.lastIndexOf(startMarker) || last !== state.lastIndexOf(endMarker)) {
    throw new Error('CODEX_STATE.md phải có đúng một cặp marker checkpoint hợp lệ.');
  }
  return { first: first + startMarker.length, last };
}

function gitSnapshot() {
  const branch = git('branch', '--show-current') || '(detached HEAD)';
  const sha = git('rev-parse', '--short=12', 'HEAD');
  // --untracked-files=all shows new files; only paths/status are read, never contents.
  // Ignore this generated document to avoid reporting a change caused by the snapshot itself.
  const lines = git('status', '--short', '--untracked-files=all').split('\n')
    .filter(Boolean)
    .filter((line) => !line.endsWith('docs/CODEX_STATE.md'));
  const visible = lines.filter((line) => !/(^|[\\/])(?:\.env(?:\.|$)|secrets[\\/])|\.(?:pem|key)(?:"|$)/i.test(line));
  const maxRows = 70;
  const output = visible.length ? visible.slice(0, maxRows).join('\n') : '(không có thay đổi ngoài CODEX_STATE.md)';
  const remaining = visible.length > maxRows ? `\n... và ${visible.length - maxRows} mục nữa; xem git status trực tiếp.` : '';
  const commits = git('log', '-3', '--format=%h %s');

  return [
    `- Ghi lúc: ${new Date().toISOString()} (UTC).`,
    `- Nhánh: \`${branch}\` · HEAD: \`${sha}\`.`,
    `- File thay đổi hiển thị: ${visible.length} (đã ẩn tên file có thể nhạy cảm và không tính chính tài liệu này).`,
    '',
    '```text', output + remaining, '```', '',
    'Ba commit gần nhất:', '', '```text', commits, '```',
    '',
    '> Ảnh chụp này chỉ phản ánh metadata Git lúc chạy lệnh. Để biết trạng thái **ngay bây giờ**, chạy `git status --short`; không suy diễn PASS từ danh sách file.',
  ].join('\n');
}

function main() {
  const action = process.argv[2] ?? '--update';
  if (!['--update', '--show', '--check'].includes(action) || process.argv.length > 3) {
    throw new Error('Cách dùng: node scripts/codex-checkpoint.mjs [--update|--show|--check]');
  }
  const state = readFileSync(statePath, 'utf8');
  const plan = readFileSync(planPath, 'utf8');
  const { first, last } = checkMarkers(state);
  if (!plan.trim().startsWith('# CODEX_PLAN')) throw new Error('CODEX_PLAN.md không hợp lệ.');
  if (action === '--check') {
    console.log('PASS: CODEX_STATE.md và CODEX_PLAN.md có cấu trúc checkpoint hợp lệ.');
  } else if (action === '--show') {
    const manual = state.slice(0, first) + '\n(ảnh chụp đã lưu được thay bằng trạng thái hiện thời)\n' + state.slice(last);
    console.log([manual.trim(), plan.trim(), '## Git tại thời điểm đọc\n' + gitSnapshot()].join('\n\n'));
  } else {
    const next = state.slice(0, first) + '\n' + gitSnapshot() + '\n' + state.slice(last);
    if (next !== state) writeFileSync(statePath, next);
    console.log('Đã cập nhật vùng ảnh chụp Git trong docs/CODEX_STATE.md.');
    console.log('Nhớ cập nhật các phần tiến độ/kiểm thử bằng kết quả thực tế.');
  }
}

try { main(); } catch (error) { console.error(error.message); process.exitCode = 1; }
