import assert from 'node:assert/strict';
import { constants, createHmac, publicEncrypt, randomBytes, randomUUID } from 'node:crypto';
import net from 'node:net';
import { setTimeout as delay } from 'node:timers/promises';
import { CLIENT_NOTIFY, PacketType, PacketStream, type Packet, encodePacket, encodeTextArray } from '../src/engine/packet';

// Run only against an isolated local native instance with fresh databases,
// a synthetic ticket secret, Card Wire v1 and the matching runtime manifest.
assert.equal(process.env.TQS_NATIVE_REGISTRY_QA, '1', 'Opt in to isolated native registry QA');
const secret = process.env.TQS_GAME_TICKET_SECRET ?? '';
assert.ok(/^[0-9a-f]{64}$/.test(secret), 'Synthetic QA ticket secret required');
const md5 = process.env.TQS_QA_MANIFEST_MD5 ?? '';
assert.ok(/^[0-9a-f]{32}$/.test(md5), 'Native runtime manifest MD5 required');
const banMinutes = Number(process.env.TQS_QA_TEMP_BAN_MINUTES ?? '5');
assert.ok([0, 5].includes(banMinutes));
const open = new Set<net.Socket>();
const prefix = 'tqs_quota_' + randomBytes(4).toString('hex');

function publicKey(bytes: Uint8Array): string {
  const header = bytes[0];
  assert.ok([2, 3].includes(header >> 5));
  const sizeClass = header & 31;
  assert.ok(sizeClass < 26);
  const start = sizeClass === 25 ? 3 : sizeClass === 24 ? 2 : 1;
  const size = sizeClass === 25 ? (bytes[1] << 8) | bytes[2] : sizeClass === 24 ? bytes[1] : sizeClass;
  assert.equal(bytes.length, start + size);
  const key = Buffer.from(bytes.subarray(start)).toString('utf8');
  assert.match(key, /^-----BEGIN (RSA )?PUBLIC KEY-----/);
  return key;
}

function login(index: number, device: string): Promise<{ outcome: string; socket: net.Socket; recorder: ReturnType<typeof connectRecorder> }> {
  const account = prefix + '_' + index;
  const expiry = Math.floor(Date.now() / 1000) + 180;
  const mac = createHmac('sha256', secret).update(`TQS1|${account}|${expiry}`).digest('hex');
  const ticket = `TQS1|${expiry}|${mac}`;
  const socket = net.createConnection({ host: '127.0.0.1', port: 19681 });
  const recorder = connectRecorder(socket);
  open.add(socket);
  socket.once('close', () => open.delete(socket));
  const stream = new PacketStream();
  return new Promise((resolve, reject) => {
    let finished = false;
    const timer = setTimeout(() => failure('login timeout'), 10000);
    function done(outcome: string) {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      if (outcome !== 'admitted') socket.destroy();
      resolve({ outcome, socket, recorder });
    }
    function failure(reason: string) {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      socket.destroy();
      reject(Error(reason));
    }
    socket.once('error', () => failure('connection error'));
    socket.once('close', () => failure('closed before admission result'));
    socket.on('data', (chunk) => {
      try {
        for (const packet of stream.push(chunk)) {
          if (finished) break;
          if (packet.command === 'NetworkDelayTest') {
            const cipher = publicEncrypt({ key: publicKey(packet.data), padding: constants.RSA_PKCS1_PADDING },
              Buffer.from(randomBytes(16).toString('hex') + ticket, 'utf8'));
            const setup = encodePacket({requestId: -2, type: CLIENT_NOTIFY, command: 'Setup',
              data: encodeTextArray([account, cipher, md5, '0.5.25', device])});
            socket.setNoDelay(true);
            socket.write(setup.subarray(0, 1));
            setTimeout(() => socket.write(setup.subarray(1, 2)), 80);
            setTimeout(() => socket.write(setup.subarray(2)), 160);
          } else if (packet.command === 'EnterLobby') {
            done('admitted');
          } else if (packet.command === 'ErrorDlg') {
            const reason = Buffer.from(packet.data).toString('utf8');
            if (reason.includes('server is full')) done('capacity');
            else if (reason.includes('more new users on this device')) done('device');
            else {
              const category = ['banned','invalid user','not approved','password','whitelist','online','too many','too fast','rate limit'].find(item => reason.includes(item));
              failure('unexpected native admission error (' + (category ?? 'unclassified') + ')');
            }
          } else if (packet.command === 'UpdatePackage') {
            failure('candidate runtime mismatch');
          }
        }
      } catch { failure('failed to process native authentication handshake'); }
    });
  });
}

function cbor(value: unknown): Buffer {
  function head(major: number, n: number) {
    assert.ok(n >= 0 && n < 65536);
    if (n < 24) return Buffer.from([major << 5 | n]);
    if (n < 256) return Buffer.from([major << 5 | 24, n]);
    return Buffer.from([major << 5 | 25, n >> 8, n & 255]);
  }
  if (typeof value === 'string') {
    const bytes = Buffer.from(value, 'utf8');
    return Buffer.concat([head(3, bytes.length), bytes]);
  }
  if (typeof value === 'number') return head(value >= 0 ? 0 : 1, value >= 0 ? value : -1-value);
  if (typeof value === 'boolean') return Buffer.from([value ? 245 : 244]);
  if (Array.isArray(value)) return Buffer.concat([head(4, value.length), ...value.map(cbor)]);
  assert.ok(value && typeof value === 'object');
  const entries = Object.entries(value);
  return Buffer.concat([head(5, entries.length), ...entries.flatMap(([key,item]) => [cbor(key), cbor(item)])]);
}
function notify(socket: net.Socket, command: string, payload: unknown = '') {
  socket.write(encodePacket({requestId: -2, type: CLIENT_NOTIFY, command, data: cbor(payload)}));
}
function connectRecorder(socket: net.Socket) {
  const packets = new PacketStream();
  const queued = new Map<string, Packet[]>();
  let failure = '';
  socket.on('data', (bytes) => {
    try {
      for (const packet of packets.push(bytes)) {
        if (packet.command === 'ErrorDlg' || packet.command === 'ErrorMsg') failure = 'native error packet';
        if ((packet.type & PacketType.REQUEST) || ['EnterRoom', 'EnterLobby', 'ChangeSelf', 'StartGame'].includes(packet.command)) {
          const list = queued.get(packet.command) ?? [];
          list.push(packet);
          queued.set(packet.command, list);
        }
      }
    } catch { failure = 'wire decoder error'; }
  });
  return {
    async wait(command: string, timeout = 18000) {
      const deadline = performance.now() + timeout;
      while (performance.now() < deadline) {
        if (failure) throw Error(failure);
        const value = queued.get(command)?.shift();
        if (value) return value;
        if (socket.destroyed) throw Error('fixture socket disconnected');
        await delay(20);
      }
      throw Error(`timed out waiting for ${command}`);
    },
  };
}
interface PlayerSnapshot { id: number; connId: number; state: string }
interface RoomSnapshot { id: number; name: string }

async function admin(id?: number) {
  const response = await fetch(`http://127.0.0.1:19000/api/lsroom${id === undefined ? '' : '?id='+id}`, {signal: AbortSignal.timeout(4000)});
  return response.json();
}
async function until<T>(label: string, check: () => T | Promise<T>, timeout = 12000) {
  const deadline=performance.now()+timeout;
  while (performance.now()<deadline) {
    const result=await check();
    if (result) return result;
    await delay(80);
  }
  throw Error(`timeout: ${label}`);
}
type Client = Awaited<ReturnType<typeof login>>;

async function create(host: Client) {
  const name='native-ownership-'+randomBytes(4).toString('hex');
  notify(host.socket,'CreateRoom',[name,2,30,{
    roomName:name,gameMode:'new_heg_mode',password:'',
    _game:{generalNum:5,generalTimeout:30,timeoutAsGeneralTimeout:true,luckTime:0,enableFreeAssign:false,enableDeputy:true,disableSameConvert:false,enableObserverViewCard:false,enableObserverViewFakeSkills:false},
    _mode:{},disabledPack:[],disabledGenerals:[]
  }]);
  await host.recorder.wait('EnterRoom');
  const id = await until('room published', async () => {
    const listing=await admin();
    assert.equal(listing.success,true);
    return (listing.data as RoomSnapshot[]).find(room => room.name === name)?.id;
  });
  assert.ok(id !== undefined);
  return id;
}
async function players(id: number): Promise<PlayerSnapshot[]> {
  const data=await admin(id);
  assert.equal(data.success,true);
  return data.data.players;
}
async function gone(id: number) {
  await until('room retired',async()=>!(await admin(id)).success);
}
try {
  const host=await login(40,randomUUID());
  const guest=await login(41,randomUUID());
  assert.equal(host.outcome,'admitted');
  assert.equal(guest.outcome,'admitted');
  await Promise.all([host.recorder.wait('EnterLobby'),guest.recorder.wait('EnterLobby')]);
  const initial=await players(0);
  assert.equal(initial.length,2);
  const ids = new Set<number>();
  for(let i=0;i<5;i++) {
    const id=await create(host);
    assert.ok(!ids.has(id)); ids.add(id);
    const members=await players(id);
    assert.equal(members.length,1);
    assert.ok(initial.some(p=>p.id===members[0].id&&p.connId===members[0].connId));
    notify(host.socket,'QuitRoom');
    await host.recorder.wait('EnterLobby');
    await gone(id);
    assert.deepEqual((await players(0)).map(p=>p.connId).sort(),initial.map(p=>p.connId).sort());
  }
  console.log(JSON.stringify({status:'PASS',lane:'repeated room create/quit',cycles:5,identityPreserved:true,retiredRoomsAbsent:true}));
  const id=await create(host);
  const hostBefore=(await players(id))[0];
  notify(guest.socket,'EnterRoom',[id,'']);
  await guest.recorder.wait('EnterRoom');
  const before=await players(id);
  assert.equal(before.length,2);
  const guestBefore=before.find(p=>p.id!==hostBefore.id);
  assert.ok(guestBefore);
  notify(guest.socket,'Ready');
  await delay(250);
  notify(host.socket,'StartGame');
  await Promise.all([host.recorder.wait('StartGame'),guest.recorder.wait('StartGame')]);
  const capability='card_wire_capability,1,TQS_HEG_CARD_WIRE,new_heg_mode';
  notify(host.socket,'PushRequest',capability);
  notify(guest.socket,'PushRequest',capability);
  await Promise.all([host.recorder.wait('CustomDialog'),guest.recorder.wait('CustomDialog')]);
  async function abandon(client: Client, original: PlayerSnapshot) {
    notify(client.socket,'QuitRoom');
    await Promise.all([client.recorder.wait('EnterLobby'),client.recorder.wait('ChangeSelf')]);
    await until('abandon socket disconnected',()=>client.socket.destroyed);
    await until('abandon replacement removed from lobby',async()=>!(await players(0)).some(p=>p.id===original.id));
  }
  await abandon(guest,guestBefore);
  const old=(await players(id)).find(p=>p.id===guestBefore.id);
  assert.ok(old&&old.state==='run'&&old.connId===guestBefore.connId);
  assert.ok((await players(id)).some(p=>p.id===hostBefore.id&&p.state==='online'&&p.connId===hostBefore.connId));
  if(banMinutes===5) {
    await assert.rejects(login(41,randomUUID()),/unexpected native admission error \(banned\)/);
    assert.ok((await players(id)).some(p=>p.id===hostBefore.id&&p.state==='online'&&p.connId===hostBefore.connId));
    console.log(JSON.stringify({status:'PASS',lane:'active voluntary abandon with production ban policy',oldRunPreserved:true,transferNotifications:true,socketDisconnected:true,freshTicketRejected:true,otherAccountUnaffected:true}));
    await abandon(host,hostBefore);
    await gone(id);
    assert.equal((await players(0)).length,0);
    await assert.rejects(login(40,randomUUID()),/unexpected native admission error \(banned\)/);
    console.log(JSON.stringify({status:'PASS',lane:'abandoned active room retires with account ban intact',roomRetired:true,bothSocketsDisconnected:true,bothFreshTicketsRejected:true}));
  } else {
    const guestRetry=await login(41,randomUUID());
    assert.equal(guestRetry.outcome,'admitted');
    await guestRetry.recorder.wait('EnterLobby');
    const guestNew=(await players(0)).find(p=>p.id===guestBefore.id);
    assert.ok(guestNew&&guestNew.state==='online'&&guestNew.connId!==guestBefore.connId);
    assert.ok((await players(id)).some(p=>p.id===guestBefore.id&&p.state==='run'&&p.connId===guestBefore.connId));
    console.log(JSON.stringify({status:'PASS',lane:'zero-duration ban fresh login alongside old Run object',oldRunAndNewOnlineCoexisted:true,distinctConnections:true}));
    await abandon(host,hostBefore);
    await gone(id);
    const after=await players(0);
    assert.equal(after.length,1);
    assert.ok(after.some(p=>p.id===guestNew.id&&p.connId===guestNew.connId&&p.state==='online'));
    console.log(JSON.stringify({status:'PASS',lane:'old room retirement preserves newer account identity',roomRetired:true,replacementSurvived:true}));
    const next=await create(guestRetry);
    const members=await players(next);
    assert.ok(members.some(p=>p.id===guestNew.id&&p.connId===guestNew.connId));
    notify(guestRetry.socket,'QuitRoom');
    await guestRetry.recorder.wait('EnterLobby');
    await gone(next);
    assert.ok((await players(0)).some(p=>p.id===guestNew.id&&p.connId===guestNew.connId&&p.state==='online'));
    console.log(JSON.stringify({status:'PASS',lane:'new account connection creates and retires next room',identityPreserved:true}));
  }
} finally {
  for (const socket of open) socket.destroy();
}
