import { execFileSync } from 'node:child_process';

const [nativeName, expiryText] = process.argv.slice(2);
const alias = process.env.TQS_LIVE_QA_SSH_ALIAS ?? '';
const fail = () => {
  process.stderr.write('QA ticket helper failed\n');
  process.exit(1);
};

if (!nativeName || !/^[A-Za-z0-9_-]{1,128}$/.test(nativeName) ||
    !expiryText || !/^\d{10,}$/.test(expiryText) ||
    !/^[A-Za-z0-9_.@-]{1,128}$/.test(alias)) fail();

const python = [
  'import hashlib, hmac, pathlib, re',
  `name = ${JSON.stringify(nativeName)}`,
  `expiry = ${JSON.stringify(expiryText)}`,
  'secret = None',
  'for line in pathlib.Path("/etc/tqs-game-auth.env").read_text(encoding="utf-8").splitlines():',
  '    if line.startswith("TQS_GAME_TICKET_SECRET="): secret = line.split("=", 1)[1].strip(); break',
  'if not secret or len(secret) < 32: raise SystemExit(2)',
  'payload = f"TQS1|{name}|{expiry}".encode("utf-8")',
  'signature = hmac.new(secret.encode("utf-8"), payload, hashlib.sha256).hexdigest()',
  'print(f"TQS1|{expiry}|{signature}")',
].join('\n');

try {
  const output = execFileSync('ssh', [
    '-T',
    '-o', 'BatchMode=yes',
    '-o', 'ConnectTimeout=10',
    alias,
    'sudo', '-n', 'python3', '-',
  ], {
    input: python,
    encoding: 'utf8',
    timeout: 15_000,
    maxBuffer: 1024,
    stdio: ['pipe', 'pipe', 'pipe'],
  }).trim();
  if (!new RegExp(`^TQS1\\|${expiryText}\\|[a-f0-9]{64}$`).test(output)) fail();
  process.stdout.write(`${output}\n`);
} catch {
  fail();
}
