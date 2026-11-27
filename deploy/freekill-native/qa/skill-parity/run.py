import hashlib, json, os, re, secrets, shutil, socket, subprocess, tempfile, time, urllib.request
from pathlib import Path
import argparse

parser = argparse.ArgumentParser(description="Run isolated native skill parity QA")
parser.add_argument('--runtime', required=True, type=Path)
parser.add_argument('--source', required=True, type=Path, help='Native source containing SQL bootstrap files')
parser.add_argument('--binary', required=True, type=Path)
parser.add_argument('--rocks', required=True, type=Path, help='Lua 5.4 rocks root')
parser.add_argument('--lane', choices=('playcard', 'chain', 'hidden-main-effect', 'hidden-deputy-remove', 'hidden-black', 'hidden-unlit', 'hidden-trick', 'hidden-delayed', 'hidden-multi', 'hidden-main-remove', 'hidden-deputy-effect', 'hidden-decline', 'tl-physical', 'tl-success', 'tl-cancel', 'tl-prevent', 'liaoye'), default='playcard')
parser.add_argument('--manifest-md5', required=True)
parser.add_argument('--binary-sha256', required=True)
parser.add_argument('--gateway', action='store_true', help='Send QA clients through the loopback WebSocket gateway')
parser.add_argument('--browser-preflight', action='store_true', help='Verify Chrome boots the gateway bundle and logs into native')
args = parser.parse_args()
if args.browser_preflight and not args.gateway:
    parser.error('--browser-preflight requires --gateway')
players = 3 if args.lane in ('chain', 'hidden-multi', 'liaoye') else 2
root = Path(__file__).resolve().parent
reference = args.runtime.resolve()
source = args.source.resolve()
binary = args.binary.resolve()
modules = args.rocks.resolve()
repo = root.parents[3]
assert hashlib.sha256(binary.read_bytes()).hexdigest() == args.binary_sha256, 'binary hash mismatch'
print('Binary SHA-256', args.binary_sha256, flush=True)
for filename in ('skill-parity-native.mts', 'skill-parity-qa-init.lua'):
    print(filename, hashlib.sha256((root / filename).read_bytes()).hexdigest(), flush=True)
def ports():
    for port in (19681, 9000, *((19682,) if args.gateway else ()), *((19683,) if args.browser_preflight else ())):
        with socket.socket() as s:
            assert s.connect_ex(('127.0.0.1',port)) != 0, f'port {port} busy'
    with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as s:
        s.bind(('127.0.0.1',19681))
def lane():
    ports()
    env=dict(os.environ,TQS_GAME_TICKET_SECRET=secrets.token_hex(32),TQS_SKILL_PARITY_LANE=args.lane)
    env.pop('TQS_SKILL_PARITY_GATEWAY', None)
    with tempfile.TemporaryDirectory(prefix='qa-skill-parity-',dir=None) as tmp:
        work=Path(tmp)
        shutil.copytree(reference/'packages',work/'packages')
        config=json.loads((reference/'freekill.server.config.json').read_text())
        assert config['tqsQa']['enabled'] is False and config['tqsCardWire']['version']==1
        config['tqsAuthSecret']=''
        config['tqsQa']=dict(enabled=True,allowedUsers=[f'tqs_cup_qa_{i}' for i in range(30,30+players)],maxPlayers=players,maxActiveRooms=1,maxRunsPerProcess=1,maxDurationSeconds=90,cardWireVersion=1)
        if args.browser_preflight:
            config['tqsQa']['allowedUsers'].append('tqs_cup_qa_39')
        (work/'freekill.server.config.json').write_text(json.dumps(config))
        (work/'qa_packages/tqs_qa').mkdir(parents=True)
        shutil.copyfile(root/'skill-parity-qa-init.lua',work/'qa_packages/tqs_qa/init.lua')
        shutil.copyfile(source/'packages/init.sql',work/'packages/init.sql')
        (work/'server').mkdir()
        for name in ('init.sql','gamedb_init.sql'):
            shutil.copyfile(source/'server'/name,work/'server'/name)
        for relative in ('lib/lua/5.4','share/lua/5.4'):
            shutil.copytree(modules/relative,work/'rocks54'/relative)
        env['PATH']='/opt/homebrew/opt/lua@5.4/bin:'+env['PATH']
        env['LUA_PATH']=str(work/'rocks54/share/lua/5.4/?.lua')+';'+str(work/'rocks54/share/lua/5.4/?/init.lua')+';;'
        env['LUA_CPATH']=str(work/'rocks54/lib/lua/5.4/?.so')+';;'
        subprocess.run(['lua5.4','-e','require("socket"); require("lfs")'],env=env,cwd=work,check=True)
        relative='packages/freekill-core/lua/server/card_wire_projection.lua'
        expected=(reference/'flist.txt').read_bytes()
        expected,n=re.subn(re.escape(relative.encode())+b'=[a-f0-9]{32}',relative.encode()+b'='+hashlib.md5((work/relative).read_bytes()).hexdigest().encode(),expected)
        assert n==1
        env['TQS_QA_MANIFEST_MD5']=hashlib.md5(expected).hexdigest()
        assert env['TQS_QA_MANIFEST_MD5'] == args.manifest_md5, 'runtime manifest hash mismatch'
        print('Manifest expected',env['TQS_QA_MANIFEST_MD5'],flush=True)
        link=work/'packages/freekill-core/qa_packages'
        link.symlink_to('../../.tqs_qa-pending')
        boot=work/'boot.log'
        native=None
        gateway=None
        try:
            with boot.open('w') as stream:
                native=subprocess.Popen([str(binary),'--port','19681'],cwd=work,env=env,stdin=subprocess.PIPE,stdout=stream,stderr=subprocess.STDOUT,text=True,start_new_session=True)
            for _ in range(120):
                assert native.poll() is None,'native exited before readiness'
                if 'server is ready' in boot.read_text(errors='replace') and (work/'flist.txt').exists() and (work/'server/game.db').exists():
                    try:
                        with urllib.request.urlopen('http://127.0.0.1:9000/api/lsroom',timeout=2) as response:
                            assert json.load(response)['success'] is True
                        break
                    except OSError: pass
                time.sleep(1)
            else: raise RuntimeError('readiness timeout')
            actual=(work/'flist.txt').read_bytes()
            if actual!=expected:
                a=set(actual.decode().split(';')); b=set(expected.decode().split(';'))
                print('Manifest delta counts', len(a-b), len(b-a), flush=True)
            assert actual==expected
            link.unlink()
            link.symlink_to('../../qa_packages')
            assert all((work/'server'/name).stat().st_size>0 for name in ('users.db','game.db'))
            print('Native ready; exact manifest; fresh databases',flush=True)
            if args.gateway:
                gateway_url = 'http://127.0.0.1:19682'
                allowed_origins = gateway_url
                if args.browser_preflight:
                    allowed_origins += ',http://127.0.0.1:19683'
                gateway_env = dict(os.environ, FK_ROOT=str(work), FK_HOST='127.0.0.1', FK_PORT='19681',
                                   PORT='19682', BIND_HOST='127.0.0.1', ALLOW_ORIGIN=allowed_origins,
                                   REQUIRE_WS_ADMISSION='0', WEB_DIST='')
                gateway = subprocess.Popen(['node', str(repo/'game/gateway/src/server.mjs')],
                                           cwd=work, env=gateway_env,
                                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                for _ in range(50):
                    assert gateway.poll() is None, 'gateway exited before readiness'
                    try:
                        with urllib.request.urlopen(gateway_url + '/healthz', timeout=1) as response:
                            assert response.status == 200
                        break
                    except OSError:
                        time.sleep(0.1)
                else:
                    raise RuntimeError('gateway readiness timeout')
                with urllib.request.urlopen(gateway_url + '/manifest.json', timeout=10) as response:
                    manifest = json.load(response)
                assert manifest['md5'] == args.manifest_md5, 'gateway manifest differs from native'
                assert manifest['cardWireVersion'] == 1, 'gateway did not advertise Card Wire v1'
                assert 'tqs_qa' not in manifest['packages'], 'gateway exposed the server-only QA package'
                env['TQS_SKILL_PARITY_GATEWAY'] = 'ws://127.0.0.1:19682/ws'
                print('Gateway ready; manifest matches native; Card Wire v1; WebSocket transport enabled', flush=True)
            if args.browser_preflight:
                preflight = repo/'game/web/scripts/multiplayer-e2e/skill-parity-preflight.ts'
                result = subprocess.run([str(repo/'game/web/node_modules/.bin/tsx'), str(preflight)],
                                        cwd=repo/'game/web', env=env, capture_output=True, text=True, timeout=60)
                for line in result.stdout.splitlines():
                    if line.startswith('{"status":') and '"lane":"browser-preflight"' in line:
                        print(line, flush=True)
                print('Browser preflight exit', result.returncode, flush=True)
                assert result.returncode == 0, 'browser preflight failed'
            result=subprocess.run([str(repo/'game/web/node_modules/.bin/tsx'),str(root/'skill-parity-native.mts')],cwd=work,env=env,capture_output=True,text=True,timeout=120)
            for line in result.stdout.splitlines():
                if line.startswith('{'):
                    try: record=json.loads(line)
                    except ValueError: continue
                    if record.get('status') in ('PASS','DIAGNOSTIC'): print(line,flush=True)
            print('Client exit',result.returncode,flush=True)
            assert result.returncode==0,'client failed'
            assert '[TQS_QA_SKILL_PARITY] SUMMARY PASS' in boot.read_text(errors='replace')
        finally:
            if gateway is not None and gateway.poll() is None:
                gateway.terminate()
                try:
                    gateway.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    gateway.kill()
                    gateway.wait()
            if native is not None and native.poll() is None:
                try:
                    native.stdin.write('quit\n'); native.stdin.flush()
                    native.wait(timeout=25)
                except (OSError,subprocess.TimeoutExpired):
                    import signal
                    os.killpg(native.pid,signal.SIGTERM)
                    try: native.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        os.killpg(native.pid,signal.SIGKILL); native.wait()
            if boot.exists():
                log=boot.read_text(errors='replace')
                for line in log.splitlines():
                    if '[TQS_QA_SKILL_PARITY]' in line: print(line,flush=True)
                for line in log.splitlines():
                    if any(x in line for x in ('stack traceback','attempt to index','nil value','bad argument','assertion failed','Execution time exceed.','card_wire_projection.lua:')):
                        print('Worker diagnostic category:', next(x for x in ('stack traceback','attempt to index','nil value','bad argument','assertion failed','Execution time exceed.','card_wire_projection.lua:') if x in line), flush=True)
                errors={x:log.lower().count(x.lower()) for x in ('stack traceback','Broken pipe','Lua initialization transport failed')}
                print('Worker errors',errors,'native exit',native.returncode if native else None,flush=True)
        assert native.returncode==0 and not any(errors.values())
try:
    lane()
finally:
    ports()
    print('Cleanup PASS; ports free',flush=True)
