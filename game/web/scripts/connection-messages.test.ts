import assert from 'node:assert/strict';
import { test } from 'node:test';
import { connectionError, userFacingError } from '../src/engine/connectionMessages';
import { initialSnapshot, reduceUiEvent } from '../src/store/gameStore';

test('second login produces a clear, actionable notice in the native UI event path', () => {
  const firstSession = reduceUiEvent(initialSnapshot, 'ErrorDlg', 'others logged in again with this name');
  assert.match(firstSession.error!, /Tài khoản đã đăng nhập ở nơi khác/);
  assert.match(firstSession.error!, /thiết bị hoặc cửa sổ khác/);
  assert.match(firstSession.error!, /đăng nhập lại/);
  assert.doesNotMatch(firstSession.error!, /others logged|native|username/i);
  // A subsequent generic socket close must not replace the server's specific reason.
  const finalError = firstSession.error || connectionError('closed (1006)');
  assert.equal(finalError, firstSession.error);
});

test('native protocol variants and known admission errors are localized', () => {
  for (const native of [
    'others logged in again with this name',
    ['others logged in again with this name', 'ignored'],
    '["others logged in again with this name","ignored"]',
  ]) {
    assert.match(connectionError(native), /đã đăng nhập ở nơi khác/);
  }
  assert.match(connectionError('you have been temporarily banned!'), /tạm chặn IP/);
  assert.match(connectionError('server is full!'), /đủ số người chơi/);
  assert.match(connectionError('game account is not approved'), /chưa được cấp quyền/);
  assert.match(connectionError('username or password error'), /đăng nhập lại bằng Google/);
  assert.match(connectionError('cannot register more new users on this device'), /giới hạn đăng ký/);
});

test('generic transport failures give network guidance without claiming a second login', () => {
  for (const raw of ['closed (1006)', 'backend error', 'connect timeout', 'recovery timeout', 'backend closed']) {
    const text = connectionError(raw);
    assert.match(text, /kết nối|máy chủ/i);
    assert.doesNotMatch(text, /nơi khác|others logged/i);
  }
  assert.match(connectionError('invalid packet stream'), /tải lại trang/);
  assert.match(connectionError('Lua runtime error'), /tải lại trang/);
});

test('boot diagnostics are replaced by specific retry instructions', () => {
  assert.match(userFacingError(new Error('Manifest HTTP 503'), 'boot'), /tạm thời không khả dụng/);
  assert.match(userFacingError(new Error('Bundle checksum không khớp manifest; đã chặn đăng nhập'), 'boot'), /Dữ liệu trò chơi chưa đồng bộ/);
  assert.match(userFacingError(new Error('Gateway thiếu package FreeKill/Utility/Hegemony'), 'boot'), /Dữ liệu trò chơi chưa đồng bộ/);
  assert.match(userFacingError(new TypeError('Failed to fetch'), 'boot'), /kiểm tra mạng/);
  assert.match(userFacingError(new Error('Manifest HTTP 404'), 'boot'), /Không tải được dữ liệu/);
});

test('Google, session API codes and access control are user facing', () => {
  assert.match(userFacingError({ code: 'auth/popup-blocked', message: 'Firebase internal details' }, 'auth'), /cửa sổ bật lên/);
  assert.match(userFacingError({ code: 'auth/network-request-failed' }, 'auth'), /kiểm tra mạng/);
  assert.match(userFacingError({ code: 'GAME_ACCESS_PENDING' }, 'auth'), /chờ quản trị viên/);
  assert.match(userFacingError({ code: 'GAME_ACCESS_SUSPENDED' }, 'auth'), /tạm dừng/);
  assert.match(userFacingError({ code: 'INVALID_TOKEN' }, 'auth'), /đăng nhập lại bằng Google/);
  assert.match(userFacingError({ code: 'ACCOUNT_BANNED' }, 'auth'), /bị khóa quyền/);
  assert.match(userFacingError({ code: 'GAME_AUTH_UNAVAILABLE' }, 'auth'), /không khả dụng/);
  assert.match(userFacingError(new Error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'), 'auth'), /đăng nhập lại bằng Google/);
});

test('safe authored validation is retained but technical and arbitrary remote details are hidden', () => {
  assert.equal(userFacingError(new Error('Tên phòng phải dài từ 1 đến 80 ký tự')),
    'Tên phòng phải dài từ 1 đến 80 ký tự');
  assert.match(userFacingError(new Error('Yêu cầu chọn tướng đã hết thời gian'), 'gameplay'), /Thời gian thao tác/);
  assert.match(userFacingError(new Error('Lựa chọn không được Lua cho phép'), 'gameplay'), /chọn lại/);
  assert.equal(userFacingError({ code: 'INTERNAL_UNEXPECTED_CODE', message: 'private-socket:abc123' }, 'auth'),
    'Không thể đăng nhập lúc này. Vui lòng thử lại; nếu lỗi tiếp diễn, liên hệ ban điều hành.');
  assert.notEqual(connectionError('Mã phiên bí mật xyz đã lỗi'), 'Mã phiên bí mật xyz đã lỗi');
  for (const value of [
    { accessToken: 'secret' },
    new Error('Error: https://internal.example/api?token=secret'),
    '["raw secret error","Bearer private-token"]',
    new Error('Lua failed: stack trace at runtime.js (12:3)'),
  ]) {
    assert.doesNotMatch(userFacingError(value, 'gameplay'), /secret|token|Lua|https?:\/\/|private/i);
  }
  for (const inheritedKey of ['constructor', 'toString', '__proto__']) {
    assert.equal(connectionError(inheritedKey), 'Kết nối đến máy chủ bị gián đoạn. Hãy kiểm tra mạng và đăng nhập lại.');
    assert.equal(userFacingError({ code: inheritedKey }, 'auth'),
      'Không thể đăng nhập lúc này. Vui lòng thử lại; nếu lỗi tiếp diễn, liên hệ ban điều hành.');
  }
});
