import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

export function editOnce(file, before, after, label, previousAfter) {
  const source = fs.readFileSync(file, 'utf8');
  if (source.includes(after)) return source;
  const anchor = previousAfter && source.includes(previousAfter) ? previousAfter : before;
  assert.equal(source.split(anchor).length, 2, `${label}: source anchor drifted`);
  const next = source.replace(anchor, after);
  fs.writeFileSync(file, next);
  return next;
}

export function updateRpcStreamSource(core) {
  // A clean EOF between RPC messages is the worker shutdown signal. A truncated
  // object still goes through the ordinary decoder and raises an error.
  editOnce(path.join(core, 'lua/server/rpc/cbor.lua'),
    '  return fh:read(len);', [
      '  if len == 0 then return "" end',
      '  local bytes = fh:read(len);',
      '  assert(type(bytes) == "string" and #bytes == len, "truncated CBOR payload");',
      '  return bytes;',
    ].join('\n'), 'strict CBOR payload length');
  editOnce(path.join(core, 'lua/server/rpc/stdio.lua'),
    '    if fk._rpc_finished then return "" end',
    '    if fk._rpc_finished then return n == 0 and "" or nil end',
    'RPC stdio EOF after finish');
  editOnce(path.join(core, 'lua/server/rpc/cbor.lua'),
    '  decode_file = read_object,', [
      '  decode_file = function(fh, opts)',
      '    local byte, err = fh:read(1)',
      '    if byte == nil then',
      '      assert(err == nil, "CBOR stream read failed")',
      '      return nil',
      '    end',
      '    local header = byte:byte()',
      '    return decoder[b_rshift(header, 5)](fh, header % 32, opts)',
      '  end,',
    ].join('\n'), 'clean RPC CBOR stream EOF');
}
