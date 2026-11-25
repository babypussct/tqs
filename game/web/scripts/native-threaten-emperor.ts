import assert from 'node:assert/strict';
import { constants, createHmac, publicEncrypt, randomBytes, randomUUID } from 'node:crypto';
import net from 'node:net';
import { setTimeout as delay } from 'node:timers/promises';
import { CLIENT_NOTIFY, CLIENT_REPLY, PacketType, PacketStream, type Packet, encodePacket, encodeTextArray } from '../src/engine/packet';

// Isolated native QA only: fresh databases, synthetic tickets, explicit allowlist,
// matching manifest, and a dedicated server-only extra-turn director.
// The default lane uses physical Threaten Emperor; the concealed lane uses a synthetic reason.
assert.equal(process.env.TQS_NATIVE_THREATEN_EMPEROR_QA, '1', 'Opt in to isolated native QA');
const secret = process.env.TQS_GAME_TICKET_SECRET ?? '';
assert.match(secret, /^[0-9a-f]{64}$/);
const md5 = process.env.TQS_QA_MANIFEST_MD5 ?? '';
assert.match(md5, /^[0-9a-f]{32}$/);
const open = new Set<net.Socket>();
const prefix = 'tqs_cup_qa';
const concealed = process.env.TQS_QA_CONCEALED_EXTRA_TURN === '1';
const hiddenReason = 'tqs_qa_concealed_extra_reason';
const redactedReason = '_tqs_extra_turn';

type LoginResult = { outcome: string; socket: net.Socket; snapshotData?: Uint8Array; v1: boolean; elapsedMs: number; recorder: ReturnType<typeof connectRecorder> };
type HeldRequest = { socket: net.Socket; requestId: number };

function publicKey(bytes: Uint8Array): string {
  const header = bytes[0];
  assert.ok([2, 3].includes(header >> 5));
  const sizeClass = header & 31;
  assert.ok(sizeClass < 26);
  const start = sizeClass === 25 ? 3 : sizeClass === 24 ? 2 : 1;
  const size = sizeClass === 25 ? bytes[1] << 8 | bytes[2] : sizeClass === 24 ? bytes[1] : sizeClass;
  assert.equal(bytes.length, start + size);
  const key = Buffer.from(bytes.subarray(start)).toString("utf8");
  assert.match(key, /^-----BEGIN (RSA )?PUBLIC KEY-----/);
  return key;
}
function login(index: number, device: string, reconnect = false): Promise<LoginResult> {
  const account = prefix + "_" + index;
  const expiry = Math.floor(Date.now() / 1e3) + 180;
  const mac = createHmac("sha256", secret).update(`TQS1|${account}|${expiry}`).digest("hex");
  const ticket = `TQS1|${expiry}|${mac}`;
  const socket = net.createConnection({ host: "127.0.0.1", port: 19681 });
  open.add(socket);
  socket.once("close", () => open.delete(socket));
  const stream = new PacketStream();
  const recorder = connectRecorder(socket);
  let snapshotData: Uint8Array | undefined;
  let v1 = false;
  const start = performance.now();
  return new Promise((resolve, reject) => {
    let finished = false;
    const timer = setTimeout(() => failure("login timeout"), 1e4);
    function done(outcome: string) {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      if (outcome !== "admitted" && outcome !== "resumed") socket.destroy();
      resolve({ outcome, socket, snapshotData, v1, elapsedMs: Math.round(performance.now() - start), recorder });
    }
    function failure(reason: string) {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      socket.destroy();
      reject(Error(reason));
    }
    socket.once("error", () => failure("connection error"));
    socket.once("close", () => failure("closed before admission result"));
    socket.on("data", (chunk) => {
      try {
        for (const packet of stream.push(chunk)) {
          if (finished) break;
          if (packet.command === "NetworkDelayTest") {
            const cipher = publicEncrypt(
              { key: publicKey(packet.data), padding: constants.RSA_PKCS1_PADDING },
              Buffer.from(randomBytes(16).toString("hex") + ticket, "utf8")
            );
            const setup = encodePacket({
              requestId: -2,
              type: CLIENT_NOTIFY,
              command: "Setup",
              data: encodeTextArray([account, cipher, md5, "0.5.25", device])
            });
            socket.setNoDelay(true);
            socket.write(setup.subarray(0, 1));
            setTimeout(() => socket.write(setup.subarray(1, 2)), 80);
            setTimeout(() => socket.write(setup.subarray(2)), 160);
          } else if (packet.command === "CardWireNegotiated") {
            v1 = true;
          } else if (packet.command === "Reconnect" && reconnect) {
            snapshotData=packet.data;
            done("resumed");
          } else if (packet.command === "EnterLobby") {
            done("admitted");
          } else if (packet.command === "ErrorDlg") {
            const reason = Buffer.from(packet.data).toString("utf8");
            if (reason.includes("server is full")) done("capacity");
            else if (reason.includes("more new users on this device")) done("device");
            else {
              const category = ["banned", "invalid user", "not approved", "password", "whitelist", "online", "too many", "too fast", "rate limit"].find((item) => reason.includes(item));
              failure("unexpected native admission error (" + (category ?? "unclassified") + ")");
            }
          } else if (packet.command === "UpdatePackage") {
            failure("candidate runtime mismatch");
          }
        }
      } catch {
        failure("failed to process native authentication handshake");
      }
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
  if (typeof value === "string") {
    const bytes = Buffer.from(value, "utf8");
    return Buffer.concat([head(3, bytes.length), bytes]);
  }
  if (typeof value === "number") return head(value >= 0 ? 0 : 1, value >= 0 ? value : -1 - value);
  if (typeof value === "boolean") return Buffer.from([value ? 245 : 244]);
  if (Array.isArray(value)) return Buffer.concat([head(4, value.length), ...value.map(cbor)]);
  assert.ok(value && typeof value === "object");
  const entries = Object.entries(value);
  return Buffer.concat([head(5, entries.length), ...entries.flatMap(([key, item]) => [cbor(key), cbor(item)])]);
}
function notify(socket: net.Socket, command: string, payload: unknown = "") {
  socket.write(encodePacket({ requestId: -2, type: CLIENT_NOTIFY, command, data: cbor(payload) }));
}
function roomId(packet: Packet, name: string): number {
  const list = decode(packet.data);
  assert.ok(Array.isArray(list));
  const room = list.find(row => Array.isArray(row) && row[1] === name);
  assert.ok(room && Number.isSafeInteger(room[0]), 'fixture room missing in lobby list');
  return room[0];
}

// Native CBOR includes nested byte strings and tags. The decoder is used only
// for this fixture's packets; assertions below validate the expected shapes.
function decode(bytes: Uint8Array): any {
    const b=Buffer.from(bytes); let i=0;
    function item(): any {
      const h=b[i++], major=h>>5, ai=h&31;
      if(major===7) {
        if(ai===20||ai===21) return ai===21;
        if(ai===22||ai===23) return null;
        if(ai===26) {const x=b.readFloatBE(i);i+=4;return x;}
        if(ai===27) {const x=b.readDoubleBE(i);i+=8;return x;}
      }
      let n=ai;
      if(ai===24) n=b[i++];
      if(ai===25) {n=b.readUInt16BE(i);i+=2;}
      if(ai===26) {n=b.readUInt32BE(i);i+=4;}
      if(ai===27) {n=Number(b.readBigUInt64BE(i));i+=8;}
      if(major===0) return n;
      if(major===1) return -1-n;
      if(major===2||major===3) {const x=b.subarray(i,i+n);i+=n;return major===2?x:x.toString('utf8');}
      if(major===4) return Array.from({length:n},item);
      if(major===5) {const x=Object.create(null); for(let j=0;j<n;j++){const k=item();x[k]=item();}return x;}
      if(major===6) return item();
      throw Error('unsupported snapshot CBOR type '+major+'/'+ai);
    }
    const x=item(); assert.equal(i,b.length); return x;
  }

let playReplies=0, discardPrompts=0, accepted=0;
let heldExtraPlay: HeldRequest | undefined;
function connectRecorder(socket: net.Socket) {
  const packets = new PacketStream();
  let cardId: number | undefined, costId: number | undefined, ownerId: number | undefined;
  const seen = new Map<string, number>();
  const requests: Record<string, number> = {};
  let reasonPackets = 0;
  const extra = {markHidden:0,markPublic:0,markRedacted:0,logHidden:0,logPublic:0,logRedacted:0};
  const queued = new Map<string, Packet[]>();
  let failure = "";
  socket.on("data", (bytes) => {
    try {
      for (const packet of packets.push(bytes)) {
        if (packet.command === "ErrorDlg" || packet.command === "ErrorMsg") { failure = "native error packet"; const data=Buffer.from(packet.data).toString('utf8'); console.log(JSON.stringify({status:'DIAGNOSTIC',category:'native error packet',known:['Room creation failed','Failed to create room','failed','Lua','server','room','invalid','busy'].filter(x=>data.toLowerCase().includes(x.toLowerCase()))})); }
        if (packet.command === 'Heartbeat') {
          socket.write(encodePacket({requestId:-2,type:CLIENT_NOTIFY,command:'Heartbeat',data:new Uint8Array()}));
          continue;
        }
        const payload = Buffer.from(packet.data);
        if (payload.includes(Buffer.from(hiddenReason))) reasonPackets++;
        if (packet.command === 'SetPlayerMark' && payload.includes(Buffer.from('_extra_turn_count'))) {
          if (payload.includes(Buffer.from('tqs_qa_concealed_extra_reason'))) extra.markHidden++;
          if (payload.includes(Buffer.from('threaten_emperor_skill'))) extra.markPublic++;
          if (payload.includes(Buffer.from('_tqs_extra_turn'))) extra.markRedacted++;
        }
        if (packet.command === 'GameLog' && (payload.includes(Buffer.from('$ExtraTurnStart')) || payload.includes(Buffer.from('$ExtraTurnEnd')))) {
          if (payload.includes(Buffer.from('tqs_qa_concealed_extra_reason'))) extra.logHidden++;
          else if (payload.includes(Buffer.from('threaten_emperor_skill'))) extra.logPublic++;
          else {
            if (concealed) {
              let data = decode(packet.data);
              if (Buffer.isBuffer(data)) data = decode(data);
              assert.equal(data.cardWireVersion, 1);
              assert.equal(String(data.payload.arg), '', 'concealed log reason must be empty');
            }
            extra.logRedacted++;
          }
        }
        if (packet.type & PacketType.REQUEST) requests[packet.command] = (requests[packet.command] ?? 0) + 1;
        seen.set(packet.command, (seen.get(packet.command) ?? 0) + 1);
        if (packet.command === 'MoveCards') {
          let data=decode(packet.data);
          if (Buffer.isBuffer(data)) data=decode(data);
          if (data.cardWireVersion===1) data=data.payload;
          for (const move of data[0]) {
            if (move.toArea !== 1) continue;
            const ref=move.moveInfo[0]?.cardId;
            if (typeof ref !== 'number') continue;
            if (String(move.skillName)==='tqs_qa_te_card') {cardId=ref;ownerId=move.to;console.log(JSON.stringify({status:'DIAGNOSTIC',stage:'owner physical card received'}));}
            if (String(move.skillName)==='tqs_qa_te_cost') {costId=ref;console.log(JSON.stringify({status:'DIAGNOSTIC',stage:'owner cost received'}));}
          }
        }
        if (packet.type & PacketType.REQUEST) {
          let response: unknown;
          function choice(id: number | undefined) {
            let envelope=decode(packet.data);
            if (Buffer.isBuffer(envelope)) envelope=decode(envelope);
            assert.equal(envelope.cardWireVersion,1);
            const match=envelope.choices.find((x: { standing: number })=>x.standing===id);
            assert.ok(match && String(match.token).startsWith('h:'));
            return String(match.token);
          }
          if (packet.command === 'AskForChoices') {
            let choiceData=decode(packet.data);
            if (Buffer.isBuffer(choiceData)) choiceData=decode(choiceData);
            if (choiceData.cardWireVersion===1) choiceData=choiceData.payload;
            if (Array.isArray(choiceData[0]) && choiceData[0].length) response=[choiceData[0].some((x: unknown)=>String(x)==='Cancel')?'Cancel':String(choiceData[0][0])];
          } else if (packet.command === 'PlayCard') {
            if (!concealed && cardId!==undefined && playReplies<2) {
              response={card:choice(cardId),targets:[ownerId]};
              cardId=undefined;
              playReplies++;
            } else if ((concealed ? extra.markHidden===1 && extra.logHidden===1 : playReplies===2 && accepted===1) && !heldExtraPlay) {
              heldExtraPlay={socket,requestId:packet.requestId};
            } else response='__cancel';
          } else if (packet.command==='AskForUseActiveSkill' && payload.includes(Buffer.from('#TE-ask'))) {
            discardPrompts++;
            if (discardPrompts===2) {
              assert.ok(Number.isInteger(costId));
              response={card:{skill:'discard_skill',subcards:[choice(costId)]},targets:[]};
              accepted++;
            } else response='__cancel';
          } else if (['AskForUseCard','AskForResponseCard','AskForSkillInvoke','AskForUseActiveSkill','CustomDialog'].includes(packet.command)) response='__cancel';
          if (response!==undefined) socket.write(encodePacket({requestId:packet.requestId,type:CLIENT_REPLY,command:'',data:cbor(response)}));
        }
        if (["EnterRoom", "EnterLobby", "UpdateRoomList", "StartGame", "CardWireNegotiated", "PrepareDrawPile", "Observe", "RemoveObserver", "AddObserver", "GameOver"].includes(packet.command)) {
          const list = queued.get(packet.command) ?? [];
          list.push(packet);
          queued.set(packet.command, list);
        }
      }
    } catch (error) {
      console.log(JSON.stringify({status:"DIAGNOSTIC",category:"wire decoder error",errorClass:error instanceof Error ? error.name : "Unknown",locations:String(error instanceof Error ? error.stack : "").match(/native-threaten-emperor\.(?:mjs|ts):\d+:\d+/g)}));
      failure = "wire decoder error";
    }
  });
  return {
    seen,
    get reasonPackets() { return reasonPackets; },
    extra,
    requests,
    async wait(command: string, timeout = 18000): Promise<Packet> {
      const deadline = performance.now() + timeout;
      while (performance.now() < deadline) {
        if (failure) throw Error(failure);
        const value = queued.get(command)?.shift();
        if (value) return value;
        if (socket.destroyed) throw Error("fixture socket disconnected");
        await delay(20);
      }
      console.log(JSON.stringify({status:"DIAGNOSTIC",category:"wait timeout",command,requests,extra,gameOver:seen.get("GameOver")??0}));
      throw Error(`timed out waiting for ${command}`);
    }
  };
}
try {
  const hostDevice=randomUUID();
  const host = await login(30, hostDevice);
  const guestDevice = randomUUID();
  const guest = await login(31, guestDevice);
  assert.equal(host.outcome, "admitted");
  assert.equal(guest.outcome, "admitted");
  const observer=await login(32,randomUUID());
  assert.equal(observer.outcome,'admitted');
  const o=observer.recorder;
  const a = host.recorder;
  const b = guest.recorder;
  const name = "TQSQA/wine/0x1";
  const timeout = 12;
  notify(host.socket, "CreateRoom", [name, 2, timeout, {
    roomName: name,
    gameMode: "new_heg_mode",
    password: "",
    _game: {
      generalNum: 5,
      generalTimeout: 5,
      timeoutAsGeneralTimeout: false,
      luckTime: 0,
      enableFreeAssign: false,
      enableDeputy: true,
      disableSameConvert: false,
      enableObserverViewCard: false,
      enableObserverViewFakeSkills: false
    },
    _mode: {},
    disabledPack: [],
    disabledGenerals: []
  }]);
  await a.wait("EnterRoom");
  notify(guest.socket, "RefreshRoomList");
  const listing = await b.wait("UpdateRoomList");
  const id = roomId(listing, name);
  notify(guest.socket, "EnterRoom", [id, ""]);
  await b.wait("EnterRoom");
  const capability = "card_wire_capability,1,TQS_HEG_CARD_WIRE,new_heg_mode";
  notify(guest.socket, "Ready");
  await delay(250);
  notify(host.socket, "StartGame");
  await Promise.all([a.wait("StartGame"), b.wait("StartGame")]);
  notify(host.socket, "PushRequest", capability);
  notify(guest.socket, "PushRequest", capability);
  await Promise.all([a.wait("CardWireNegotiated"), b.wait("CardWireNegotiated")]);
  await Promise.all([a.wait("PrepareDrawPile", 4e4), b.wait("PrepareDrawPile", 4e4)]);
  const deadline=performance.now()+90000;
  while(!heldExtraPlay && performance.now()<deadline) await delay(20);
  console.log(JSON.stringify({status:'DIAGNOSTIC',held:!!heldExtraPlay,heldByHost:heldExtraPlay?.socket===host.socket,playReplies,discardPrompts,accepted,a:a.extra,b:b.extra,requestsA:a.requests,requestsB:b.requests}));
  assert.ok(heldExtraPlay,'extra-turn PlayCard request required');
  const hostOwns=heldExtraPlay.socket===host.socket;
  assert.ok(hostOwns || heldExtraPlay.socket===guest.socket);
  const ownerRecorder=hostOwns?a:b;
  const opponent=hostOwns?guest:host;
  const opponentIndex=hostOwns?31:30;
  const opponentDevice=hostOwns?guestDevice:hostDevice;
  if (concealed) {
    assert.equal(ownerRecorder.extra.markHidden,1);
    assert.equal(ownerRecorder.extra.logHidden,1);
    assert.equal(opponent.recorder.extra.markRedacted,1);
    assert.equal(opponent.recorder.extra.logRedacted,1);
    assert.equal(opponent.recorder.reasonPackets,0);
  } else {
    assert.equal(a.extra.markPublic,1);
    assert.equal(b.extra.markPublic,1);
  }
  function validateSnapshot(bytes: Uint8Array | undefined, observer: boolean) {
    assert.ok(bytes);
    if (concealed) assert.ok(!Buffer.from(bytes).includes(Buffer.from(hiddenReason)), "snapshot leaked concealed reason");
    let envelope=decode(bytes);
    if (Buffer.isBuffer(envelope)) envelope=decode(envelope);
    assert.equal(envelope.cardWireVersion,1);
    const state=envelope.payload;
    if (observer) assert.equal(state.settings.isObserver,true);
    assert.deepEqual(Object.keys(state.card_manager.draw_pile),['count']);
    assert.ok(state.card_manager.draw_pile.count>0);
    const seats=Object.values(state.players) as Array<{ mark?: Uint8Array; player_cards: unknown[][]; fake_skills: unknown[] }> ;
    assert.equal(seats.length,2);
    let marked=0,hidden=0;
    for(const seat of seats) {
      const marks=seat.mark?decode(seat.mark):{};
      const reasons=marks._extra_turn_count;
      if(Array.isArray(reasons)&&reasons.length) {
        assert.deepEqual(reasons.map(String),[concealed ? redactedReason : 'threaten_emperor_skill']);
        marked++;
      }
      const hand=Array.isArray(seat.player_cards)?seat.player_cards[0]:seat.player_cards[1];
      assert.ok(Array.isArray(hand));
      for(const ref of (observer || Array.isArray(reasons)&&reasons.length ? hand : [])) {
        assert.ok((typeof ref==='string'||Buffer.isBuffer(ref))&&String(ref).startsWith('h:'),'outsider hand ref must be opaque');
        hidden++;
      }
      if(observer) assert.equal(seat.fake_skills.length??Object.keys(seat.fake_skills).length,0);
    }
    assert.equal(marked,1);
    assert.ok(hidden>0);
    return hidden;
  }
  notify(observer.socket,'ObserveRoom',[id,'',capability]);
  await o.wait('CardWireNegotiated',5000);
  const observed=validateSnapshot((await o.wait('Observe',5000)).data,true);
  console.log(JSON.stringify({status:'PASS',lane:'observer snapshot during actual extra turn',publicReason:!concealed,concealedReasonRedacted:concealed,deckCountOnly:true,opaqueHandRefs:observed}));
  opponent.socket.destroy();
  await delay(400);
  const resumed=await login(opponentIndex,opponentDevice,true);
  assert.equal(resumed.outcome,'resumed');
  assert.equal(resumed.v1,true);
  const b2=resumed.recorder;
  const reconnected=validateSnapshot(resumed.snapshotData,false);
  assert.equal(concealed ? ownerRecorder.extra.logHidden : ownerRecorder.extra.logPublic,1,'extra turn must still be active');
  console.log(JSON.stringify({status:'PASS',lane:'opponent reconnect during actual extra turn',publicReason:!concealed,concealedReasonRedacted:concealed,deckCountOnly:true,opaqueHandRefs:reconnected,elapsedMs:resumed.elapsedMs}));
  socketReply(heldExtraPlay);
  function socketReply(held: HeldRequest) { held.socket.write(encodePacket({requestId:held.requestId,type:CLIENT_REPLY,command:'',data:cbor('__cancel')})); }
  await Promise.all([ownerRecorder.wait('GameOver',60000),b2.wait('GameOver',60000),o.wait('GameOver',60000)]);
  if (concealed) {
    assert.equal(ownerRecorder.extra.logHidden,2);
    assert.equal(b2.extra.logRedacted,1);
    assert.equal(o.extra.logRedacted,1);
    assert.equal(b2.reasonPackets,0);
    assert.equal(o.reasonPackets,0);
    assert.equal(opponent.recorder.reasonPackets,0);
    console.log(JSON.stringify({status:"PASS",lane:"concealed reason live mark and logs",ownerMarks:ownerRecorder.extra.markHidden,ownerLogs:ownerRecorder.extra.logHidden,outsiderLeaks:0,observerLeaks:0,reconnectLeaks:0}));
  } else {
    assert.equal(ownerRecorder.extra.logPublic,2);
    assert.equal(b2.extra.logPublic,1);
    assert.equal(o.extra.logPublic,1);
  }
  console.log(JSON.stringify({status:'PASS',lane:'extra turn completes after observer and reconnect',gameOverAudiences:3}));
  console.log(JSON.stringify({status:'DIAGNOSTIC',playReplies,discardPrompts,accepted,a:a.extra,b:b.extra,requestsA:a.requests,requestsB:b.requests}));
  if (!concealed) {
    assert.equal(playReplies,2);
    assert.equal(discardPrompts,2);
    assert.equal(accepted,1);
    console.log(JSON.stringify({status:'PASS',lane:'physical Threaten Emperor native requests',playReplies,discardPrompts,accepted,gameOverNotifications:3,bounded:true}));
  }
} catch(error) {
  console.log(JSON.stringify({status:'DIAGNOSTIC',errorClass:error instanceof Error ? error.name : "Unknown",category:['native error packet','wire decoder error','timed out waiting for CardWireNegotiated','timed out waiting for Observe','unsupported snapshot CBOR type','fixture socket disconnected','nonempty hands must be observed'].find(x=>String(error instanceof Error ? error.message : "").includes(x))??'other',locations:String(error instanceof Error ? error.stack : "").match(/native-threaten-emperor\.(?:mjs|ts):\d+:\d+/g)}));
  process.exitCode=1;
} finally {
  for (const socket of open) socket.destroy();
}
