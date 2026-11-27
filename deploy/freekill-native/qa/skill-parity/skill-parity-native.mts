import assert from "node:assert/strict";
import { constants, createHmac, publicEncrypt, randomBytes, randomUUID } from "node:crypto";
import net from "node:net";
import { createRequire } from "node:module";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as delay } from "node:timers/promises";

import { CLIENT_NOTIFY, CLIENT_REPLY, encodePacket, encodeTextArray, PacketStream, RawPacketStream } from "../../../../game/web/src/engine/packet.ts";
var fixtureDir = dirname(fileURLToPath(import.meta.url));
var secret = process.env.TQS_GAME_TICKET_SECRET;
assert.match(secret, /^[0-9a-f]{64}$/);
var md5 = process.env.TQS_QA_MANIFEST_MD5;
var open = /* @__PURE__ */ new Set();
var timings = [];
var prefix = "tqs_cup_qa";
const gatewayUrl = process.env.TQS_SKILL_PARITY_GATEWAY;

function connect() {
  if (gatewayUrl) {
    assert.equal(gatewayUrl, "ws://127.0.0.1:19682/ws");
    const requireGateway = createRequire(new URL("../../../../game/gateway/package.json", import.meta.url));
    const { WebSocket, createWebSocketStream } = requireGateway("ws");
    return createWebSocketStream(new WebSocket(gatewayUrl, { origin: "http://127.0.0.1:19682" }));
  }
  const socket = net.createConnection({ host: "127.0.0.1", port: 19681 });
  socket.setNoDelay(true);
  return socket;
}
function publicKey(bytes) {
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
function login(index, device, reconnect = false) {
  const account = prefix + "_" + index;
  const expiry = Math.floor(Date.now() / 1e3) + 180;
  const mac = createHmac("sha256", secret).update(`TQS1|${account}|${expiry}`).digest("hex");
  const ticket = `TQS1|${expiry}|${mac}`;
  const socket = connect();
  open.add(socket);
  socket.once("close", () => open.delete(socket));
  const stream = new PacketStream();
  const raw = new RawPacketStream();
  let snapshotBytes = 0;
  let v1 = false;
  let playerId: number | undefined;
  const start = performance.now();
  return new Promise((resolve, reject) => {
    let finished = false;
    const timer = setTimeout(() => failure("login timeout"), 1e4);
    function done(outcome) {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      if (outcome === "admitted") timings.push(Math.round(performance.now() - start));
      else if (outcome !== "resumed") socket.destroy();
      resolve({ outcome, socket, snapshotBytes, v1, playerId, elapsedMs: Math.round(performance.now() - start) });
    }
    function failure(reason) {
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
        if (reconnect && !finished) {
          for (const packet of raw.push(chunk)) {
            if (packet.command === "Reconnect") snapshotBytes = packet.bytes.length;
          }
        }
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
            socket.write(setup.subarray(0, 1));
            setTimeout(() => socket.write(setup.subarray(1, 2)), 80);
            setTimeout(() => socket.write(setup.subarray(2)), 160);
          } else if (packet.command === "Setup") {
            playerId = decodeQa(packet.data)[0];
            assert.ok(Number.isSafeInteger(playerId));
          } else if (packet.command === "CardWireNegotiated") {
            v1 = true;
          } else if (packet.command === "Reconnect" && reconnect) {
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
function cbor(value) {
  function head(major, n) {
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
function notify(socket, command, payload = "") {
  socket.write(encodePacket({ requestId: -2, type: CLIENT_NOTIFY, command, data: cbor(payload) }));
}
function roomId(packet, name) {
  const bytes = Buffer.from(packet.data);
  let offset = 0;
  function item() {
    const header = bytes[offset++];
    const major = header >> 5;
    const width = header & 31;
    let value = width;
    if (width === 24) {
      value = bytes[offset++];
    }
    if (width === 25) {
      value = bytes.readUInt16BE(offset);
      offset += 2;
    }
    if (width === 26) {
      value = bytes.readUInt32BE(offset);
      offset += 4;
    }
    if (major === 0) return value;
    if (major === 2 || major === 3) {
      const str = bytes.toString("utf8", offset, offset + value);
      offset += value;
      return str;
    }
    if (major === 4) return Array.from({ length: value }, item);
    if (major === 7 && [20, 21].includes(width)) return width === 21;
    throw Error("unexpected room list format");
  }
  const list = item();
  assert.ok(Array.isArray(list));
  const room = list.find((row) => Array.isArray(row) && row[1] === name);
  assert.ok(room && Number.isSafeInteger(room[0]), "fixture room missing in lobby list");
  return room[0];
}
function decodeQa(bytes) {
  const b=Buffer.from(bytes); let i=0;
  function item() {
    const h=b[i++], major=h>>5, ai=h&31;
    if(major===7 && [20,21,22,23].includes(ai)) return ai===21?true:ai===20?false:null;
    let n=ai;
    if(ai===24) n=b[i++];
    if(ai===25) {n=b.readUInt16BE(i);i+=2;}
    if(ai===26) {n=b.readUInt32BE(i);i+=4;}
    if(ai===27) {n=Number(b.readBigUInt64BE(i));i+=8;}
    if(major===0) return n;
    if(major===1) return -1-n;
    if(major===2||major===3) {const x=b.subarray(i,i+n);i+=n;return major===2?x:x.toString('utf8');}
    if(major===4) return Array.from({length:n},item);
    if(major===5) {const x=Object.create(null);for(let j=0;j<n;j++){const k=item();x[k]=item();}return x;}
    if(major===6) return {tag:n,value:item()};
    throw Error('unsupported QA CBOR');
  }
  let x=item();assert.equal(i,b.length);return Buffer.isBuffer(x)?decodeQa(x):x;
}

const lane = process.env.TQS_SKILL_PARITY_LANE ?? "playcard";
const chainLane = lane === "chain";
const liaoyeLane = lane === "liaoye";
const tlSuffix = {"tl-physical":"0x12", "tl-success":"0x13", "tl-cancel":"0x14", "tl-prevent":"0x15"}[lane];
const hiddenSuffix = {"hidden-main-effect":"0x2", "hidden-deputy-remove":"0x3", "hidden-black":"0x4", "hidden-unlit":"0x5", "hidden-trick":"0x6", "hidden-delayed":"0x7", "hidden-multi":"0x8", "hidden-main-remove":"0x9", "hidden-deputy-effect":"0x10", "hidden-decline":"0x11"}[lane];
const playerCount = chainLane || liaoyeLane || lane === "hidden-multi" ? 3 : 2;
const hiddenPositive = ["hidden-main-effect", "hidden-deputy-remove", "hidden-trick", "hidden-main-remove", "hidden-deputy-effect"].includes(lane);
let hiddenGates = 0, hiddenInvokes = 0, hiddenCardChoices = 0;
let jilixChoices=0, discardPrompts=0, showPrompts=0, playPrompts=0;
function connectRecorder(socket) {
  const packets = new PacketStream();
  const raw = new RawPacketStream();
  let capture = false;
  const sizes = [];
  const marks = [], hpUpdates = [];
  const seen = /* @__PURE__ */ new Map();
  const queued = /* @__PURE__ */ new Map();
  let failure = "";
  let seats: number[] = [];
  const liaoyeLogs = [];
  let liaoyeSelections = 0;
  let liaoyeChoices = 0;
  let hiddenPrelightAcks = 0;
  let hiddenPhase = 0;
  const hiddenPrivateMarks = [], hiddenFakeSkills = [], hiddenPublicGenerals = [];
  let hiddenGateRequest: number | undefined;
  const chainMoves: {from: number, to: number, toArea: number, fromArea: number, ref: string | number, label: string, retired: (string | number)[]}[] = [];
  const chainShows: {source: number, refs: (string | number)[]}[] = [];
  function cardRef(value: unknown): string | number {
    if (typeof value === "number") return value;
    assert.ok(typeof value === "string" || Buffer.isBuffer(value), "invalid card reference type");
    return String(value);
  }
  socket.on("data", (bytes) => {
    try {
      if (capture) {
        for (const wire of raw.push(bytes)) sizes.push(wire.bytes.length);
      } else raw.push(bytes);
      for (const packet of packets.push(bytes)) {
        if (packet.command === "ErrorDlg" || packet.command === "ErrorMsg") { failure = "native error packet"; const data=Buffer.from(packet.data).toString('utf8'); console.log(JSON.stringify({status:'DIAGNOSTIC',category:'native error packet',known:['Room creation failed','Failed to create room','failed','Lua','server','room','invalid','busy'].filter(x=>data.toLowerCase().includes(x.toLowerCase()))})); }
        seen.set(packet.command, (seen.get(packet.command) ?? 0) + 1);
        const payload = Buffer.from(packet.data);
        if (packet.command === "Heartbeat") {
          socket.write(encodePacket({requestId:-2,type:CLIENT_NOTIFY,command:"Heartbeat",data:new Uint8Array()}));
        }
        if (packet.command === "ArrangeSeats") {
          seats = decodeQa(payload);
          assert.equal(seats.length, playerCount);
          assert.ok(seats.every(Number.isSafeInteger));
        }
        if (liaoyeLane && packet.command === "GameLog") {
          const decoded = decodeQa(payload);
          const log = decoded.cardWireVersion === 1 ? decoded.payload : decoded;
          if (String(log.type).startsWith("#heg__liaoye-")) {
            liaoyeLogs.push({ type: String(log.type), from: log.from,
              to: log.to ?? [], arg: log.arg === undefined ? undefined : String(log.arg) });
          }
        }
        if (chainLane && (packet.command === "MoveCards" || packet.command === "ShowCard")) {
          const decoded = decodeQa(payload);
          const body = decoded.cardWireVersion === 1 ? decoded.payload : decoded;
          if (packet.command === "MoveCards") {
            for (const move of body[0]) {
              for (const info of move.moveInfo) {
                chainMoves.push({from: move.from, to: move.to, toArea: move.toArea,
                  fromArea: info.fromArea, ref: cardRef(info.cardId), label: String(move.skillName ?? ""),
                  retired: (info.cardWireRetiredRefs ?? []).map(cardRef)});
              }
            }
          } else {
            chainShows.push({source: body[1], refs: body[0].map(cardRef)});
          }
        }
        if (hiddenSuffix && packet.command === "SetPlayerMark") {
          const [id, key, value] = decodeQa(payload);
          const mark = String(key);
          if (mark === "tqs_qa_hidden_phase") {
            assert.equal(id, seats[0]);
            assert.equal(value, hiddenPhase + 1);
            hiddenPhase = value;
          } else if (hiddenPhase === 1 && (mark === "__heg_general" || mark === "__heg_deputy")) {
            hiddenPrivateMarks.push({id, mark, value: String(value)});
          }
        }
        if (hiddenSuffix && hiddenPhase === 1 && packet.command === "AddSkill") {
          const [id, name, fake] = decodeQa(payload);
          if (fake === true) hiddenFakeSkills.push({id, name: String(name)});
        }
        if (hiddenSuffix && hiddenPhase === 1 && packet.command === "PropertyUpdate") {
          const [id, key, value] = decodeQa(payload);
          const slot = String(key);
          if (slot === "general" || slot === "deputyGeneral") hiddenPublicGenerals.push({id, slot, value: String(value)});
        }
        if (hiddenSuffix && packet.command === "PrelightSkill" && payload.includes(Buffer.from("ld__jilix"))) {
          hiddenPrelightAcks++;
          console.log(JSON.stringify({status:"DIAGNOSTIC",stage:"prelight acknowledgement"}));
          assert.ok(hiddenGateRequest !== undefined, "unsolicited Ký Ly prelight acknowledgement");
          socket.write(encodePacket({requestId:hiddenGateRequest,type:CLIENT_REPLY,command:"",data:cbor("1")}));
          hiddenGateRequest = undefined;
        }
        if (packet.type === 2 || ["PlayCard", "AskForChoices", "AskForUseActiveSkill", "AskForUseCard", "AskForResponseCard", "AskForSkillInvoke", "AskForCardChosen"].includes(packet.command)) {
          let response;
          if (liaoyeLane && packet.command === "PlayCard") {
            assert.equal(decodeQa(payload).cardWireVersion, 1);
            response = {card: {skill: "heg__liaoye", subcards: []}, targets: [seats[1]]};
            playPrompts++;
          } else if (liaoyeLane && packet.command === "AskForUseActiveSkill" && payload.includes(Buffer.from("#heg__liaoye-choose"))) {
            const env = decodeQa(payload);
            assert.equal(env.cardWireVersion, 1);
            assert.deepEqual(env.payload[3].targets, seats);
            liaoyeSelections++;
            response = liaoyeSelections === 3 ? "__cancel" :
              {card: {skill: "choose_players_skill", subcards: []}, targets: [seats[0], seats[2]]};
          } else if (liaoyeLane && packet.command === "AskForUseActiveSkill" && payload.includes(Buffer.from("#heg__liaoye-choice"))) {
            const env = decodeQa(payload);
            assert.equal(env.cardWireVersion, 1);
            liaoyeChoices++;
            assert.deepEqual(env.payload[3].targets, liaoyeChoices === 3 ? [] : [seats[0], seats[2]]);
            if (liaoyeChoices < 4) {
              response = {card: {skill: "#heg__liaoye_active", subcards: []}, targets: [],
                interaction_data: liaoyeChoices === 1 ? "heg__liaoye_chosen" : "heg__liaoye_unchosen"};
            }
          } else if (hiddenSuffix && packet.command === "AskForSkillInvoke" && payload.includes(Buffer.from("tqs_qa_hidden_jilix_gate"))) {
            hiddenGates++;
            console.log(JSON.stringify({status:"DIAGNOSTIC",stage:"readiness gate received"}));
            if (lane === "hidden-unlit") {
              socket.write(encodePacket({requestId:packet.requestId,type:CLIENT_REPLY,command:"",data:cbor("1")}));
            } else {
              hiddenGateRequest = packet.requestId;
              notify(socket, "PushRequest", "prelight,ld__jilix,true");
            }
          } else if (hiddenSuffix && packet.command === "AskForSkillInvoke" && payload.includes(Buffer.from("ld__jilix"))) {
            hiddenInvokes++;
            response=lane === "hidden-decline" ? "__cancel" : "1";
          } else if (packet.command === "PlayCard") {
            const env = decodeQa(payload);
            assert.equal(env.cardWireVersion, 1);
            assert.equal(env.choices.length, hiddenSuffix ? 1 : 2);
            assert.equal(seats.length, playerCount);
            const token = String(env.choices[0].token);
            assert.ok(token.startsWith("h:"));
            response = {
              card: hiddenSuffix || lane === "tl-physical" || (!tlSuffix && !chainLane && playPrompts === 0) ? token : {skill: "ld__chenglue", subcards: [token]},
              targets: lane === "hidden-multi" ? [seats[1], seats[2]] : [seats[1]],
            };
            playPrompts++;
          } else if (packet.command === "AskForChoices" && payload.includes(Buffer.from("ld__jilix"))) {
            assert.ok(payload.includes(Buffer.from("ld__jilix_effect")) && payload.includes(Buffer.from("ld__jilix_remove")));
            response=[hiddenSuffix ? (lane.endsWith("-remove") ? "ld__jilix_remove" : "ld__jilix_effect") : (jilixChoices % 2 === 0 ? "ld__jilix_effect" : "ld__jilix_remove")];
            jilixChoices++;
          } else if (lane === "hidden-trick" && packet.command === "AskForCardChosen") {
            const env = decodeQa(payload);
            assert.equal(env.cardWireVersion, 1);
            assert.equal(env.choices.length, 2 - hiddenCardChoices);
            response = String(env.choices[0].token);
            assert.ok(response.startsWith("h:"));
            hiddenCardChoices++;
          } else if (packet.command === "AskForUseActiveSkill" && (payload.includes(Buffer.from("#fire_attack-show")) || payload.includes(Buffer.from("#fire_attack-discard")))) {
            const show=payload.includes(Buffer.from("#fire_attack-show"));
            if (!show && (++discardPrompts === 3 && !chainLane && !tlSuffix || lane === "tl-cancel")) response="__cancel";
            else {
              let env=decodeQa(payload);
              assert.equal(env.cardWireVersion,1);
              const token=env.choices.find(x=>String(x.token).startsWith("h:"))?.token;
              assert.ok(token,"missing standing choice");
              response={card:{skill:show?"choose_cards_skill":"discard_skill",subcards:[String(token)]},targets:[]};
              if(show) showPrompts++;
            }
          } else if (["AskForUseCard","AskForResponseCard","AskForSkillInvoke","AskForUseActiveSkill"].includes(packet.command)) response="__cancel";
          if(response!==undefined) socket.write(encodePacket({requestId:packet.requestId,type:CLIENT_REPLY,command:"",data:cbor(response)}));
        }
        if (packet.command === "PropertyUpdate" && payload.includes(Buffer.from("hp"))) {
          const item = decodeQa(payload);
          const property = Buffer.isBuffer(item[1]) ? item[1].toString("utf8") : item[1];
          if(property === "hp") hpUpdates.push([item[0],item[2]]);
        }
        if (["EnterRoom", "EnterLobby", "UpdateRoomList", "StartGame", "CardWireNegotiated", "PrepareDrawPile", "Observe", "RemoveObserver", "AddObserver", "GameOver"].includes(packet.command)) {
          const list = queued.get(packet.command) ?? [];
          list.push(packet);
          queued.set(packet.command, list);
        }
      }
    } catch (error) {
      console.log(JSON.stringify({status:"DIAGNOSTIC", category:"decoder", errorClass:error.name, line:String(error.stack).match(/skill-parity-native\.mts:\d+:\d+/)?.[0]}));
      failure = "wire decoder error";
    }
  });
  return {
    sizes,
    seen, marks, hpUpdates, chainMoves, chainShows,
    liaoyeLogs,
    get liaoyeSelections() { return liaoyeSelections; },
    get liaoyeChoices() { return liaoyeChoices; },
    get seats() { return seats; },
    get hiddenPrelightAcks() { return hiddenPrelightAcks; },
    get hiddenPhase() { return hiddenPhase; },
    hiddenPrivateMarks, hiddenFakeSkills, hiddenPublicGenerals,
    begin() {
      capture = true;
    },
    async wait(command, timeout = 18e3) {
      const deadline = performance.now() + timeout;
      while (performance.now() < deadline) {
        if (failure) throw Error(failure);
        const value = queued.get(command)?.shift();
        if (value) return value;
        if (socket.destroyed) throw Error("fixture socket disconnected");
        await delay(20);
      }
      throw Error(`timed out waiting for ${command}`);
    }
  };
}
try {
  const clients = [];
  for (let index = 0; index < playerCount; index++) {
    const client = await login(30 + index, randomUUID());
    assert.equal(client.outcome, "admitted");
    clients.push({...client, recorder: connectRecorder(client.socket)});
  }
  const [host, guest] = clients;
  const a = host.recorder;
  const b = guest.recorder;
  const name = "TQSQA/skill-parity/" + (liaoyeLane ? "0x16" : hiddenSuffix ?? tlSuffix ?? "0x1");
  const timeout = 12;
  notify(host.socket, "CreateRoom", [name, playerCount, timeout, {
    roomName: name,
    gameMode: "new_heg_mode",
    password: "",
    _game: {
      generalNum: 5,
      generalTimeout: timeout,
      timeoutAsGeneralTimeout: true,
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
  for (const client of clients.slice(1)) {
    notify(client.socket, "EnterRoom", [id, ""]);
    await client.recorder.wait("EnterRoom");
    notify(client.socket, "Ready");
  }
  const capability = "card_wire_capability,1,TQS_HEG_CARD_WIRE,new_heg_mode";
  await delay(250);
  for (const client of clients) client.recorder.begin();
  notify(host.socket, "StartGame");
  await Promise.all(clients.map(client => client.recorder.wait("StartGame")));
  for (const client of clients) notify(client.socket, "PushRequest", capability);
  await Promise.all(clients.map(client => client.recorder.wait("CardWireNegotiated")));
  await Promise.all(clients.map(client => client.recorder.wait("PrepareDrawPile", 4e4)));
  await Promise.all(clients.map(client => client.recorder.wait("GameOver", 45000)));
  if (liaoyeLane) {
    assert.equal(playPrompts, 4);
    const automatic = clients[0].recorder.liaoyeLogs.at(-1)?.arg;
    assert.ok(automatic === "heg__liaoye_chosen" || automatic === "heg__liaoye_unchosen");
    for (const {recorder, playerId} of clients) {
      const [owner, chooser, other] = recorder.seats;
      const selected = {type: "#heg__liaoye-selected", from: chooser, to: [owner, other], arg: undefined};
      const none = {type: "#heg__liaoye-selected-none", from: chooser, to: [], arg: undefined};
      const choice = (arg: string) => ({type: "#heg__liaoye-damage-choice", from: owner, to: [], arg});
      assert.deepEqual(recorder.liaoyeLogs, [
        selected, choice("heg__liaoye_chosen"),
        selected, choice("heg__liaoye_unchosen"),
        none, choice("heg__liaoye_unchosen"),
        selected, {type: "#heg__liaoye-damage-auto", from: owner, to: [], arg: automatic},
      ]);
      assert.deepEqual(recorder.hpUpdates.at(-1), [automatic === "heg__liaoye_chosen" ? other : chooser, 9]);
      assert.equal(recorder.liaoyeSelections, playerId === chooser ? 4 : 0);
      assert.equal(recorder.liaoyeChoices, playerId === owner ? 4 : 0);
    }
    console.log(JSON.stringify({status: "PASS", lane, cases: 4, publicLogAudiences: 3, ownerOnlyDamageChoice: true}));
  } else if (hiddenSuffix) {
    assert.equal(hiddenGates, 1);
    assert.equal(playPrompts, 1);
    assert.equal(hiddenCardChoices, lane === "hidden-trick" ? 2 : 0);
    assert.equal(hiddenInvokes, hiddenPositive || lane === "hidden-decline" ? 1 : 0);
    assert.equal(jilixChoices, hiddenPositive ? 1 : 0);
    for (const client of clients) {
      const {recorder, playerId} = client;
      const actorId = recorder.seats[1];
      const deputy = lane.includes("deputy") || lane === "hidden-unlit";
      const slot = deputy ? "deputyGeneral" : "general";
      const otherSlot = deputy ? "general" : "deputyGeneral";
      const mark = deputy ? "__heg_deputy" : "__heg_general";
      const otherMark = deputy ? "__heg_general" : "__heg_deputy";
      assert.equal(recorder.hiddenPhase, 2);
      assert.ok(recorder.hiddenPrivateMarks.every(item => item.id === playerId), "private general mark audience");
      assert.ok(recorder.hiddenFakeSkills.every(item => item.id === playerId), "fake skill audience");
      const privateMarks = recorder.hiddenPrivateMarks.filter(item => item.id === actorId);
      assert.equal(privateMarks.some(item => item.mark === mark && item.value === "ld__yanbaihu"), playerId === actorId);
      assert.equal(privateMarks.some(item => item.mark === otherMark && item.value === "ld__huangzu"), playerId === actorId);
      assert.equal(recorder.hiddenFakeSkills.some(item => item.id === actorId && item.name === "ld__jilix"), playerId === actorId);
      const publicGenerals = recorder.hiddenPublicGenerals.filter(item => item.id === actorId);
      assert.ok(publicGenerals.every(item => item.slot !== otherSlot || item.value === "anjiang"), "other slot remains concealed");
      const revealed = publicGenerals.filter(item => item.slot === slot && item.value !== "anjiang").map(item => item.value);
      assert.equal(revealed.includes("ld__yanbaihu"), hiddenPositive);
      assert.equal(revealed.includes("blank_shibing"), lane.endsWith("-remove"));
      assert.ok(revealed.every(value => value === "ld__yanbaihu" || value === "blank_shibing"));
      assert.equal(client.recorder.hiddenPrelightAcks, lane !== "hidden-unlit" && client.playerId === client.recorder.seats[1] ? 1 : 0);
    }
    console.log(JSON.stringify({status:"PASS",lane,hiddenGates,hiddenInvokes,jilixChoices,prelightOwnerOnly:true,privateMarksOwnerOnly:true,fakeSkillsOwnerOnly:true,publicRevealSlotOnly:true,cardChoiceReplies:hiddenCardChoices}));
  } else {
  assert.equal(jilixChoices, chainLane || tlSuffix ? 0 : 4);
  assert.equal(discardPrompts, chainLane || tlSuffix ? 1 : 4);
  assert.equal(showPrompts, chainLane || tlSuffix ? 1 : 4);
  assert.equal(playPrompts, chainLane || tlSuffix ? 1 : 4);
  for (const {recorder} of clients) {
    assert.ok(recorder.hpUpdates.some(([,hp])=>hp===(chainLane || lane === "tl-physical" || lane === "tl-success" ? 9 : tlSuffix ? 10 : 8)));
  }
  if (chainLane) {
    const grants = clients.map(({recorder, playerId}) => ({
      playerId,
      seats: recorder.seats,
      third: recorder.chainMoves.filter(move => move.label === "tqs_qa_parity_third"),
      shown: recorder.chainMoves.filter(move => move.label === "tqs_qa_parity_shown"),
    }));
    console.log(JSON.stringify({status:'DIAGNOSTIC',stage:'chain grants',audiences:grants.map(grant=>({third:grant.third.map(move=>typeof move.ref),shown:grant.shown.map(move=>typeof move.ref)}))}));
    const thirdOwners = grants.filter(grant => grant.playerId === grant.seats[2]);
    const shownOwners = grants.filter(grant => grant.playerId === grant.seats[1]);
    assert.equal(thirdOwners.length, 1);
    assert.equal(shownOwners.length, 1);
    const thirdRef = thirdOwners[0].third[0].ref;
    const shownRef = shownOwners[0].shown[0].ref;
    assert.ok(typeof thirdRef === "number" && typeof shownRef === "number" && thirdRef !== shownRef,
      "owners must receive distinct physical card references");
    const thirdAliases = new Set<string>();
    for (const [index, {recorder}] of clients.entries()) {
      const {chainMoves, chainShows, seats} = recorder;
      const third = chainMoves.filter(move => move.label === "tqs_qa_parity_third");
      const shown = chainMoves.filter(move => move.label === "tqs_qa_parity_shown");
      assert.equal(third.length, 1);
      assert.equal(shown.length, 1);
      assert.ok(third[0].to === seats[2] && third[0].toArea === 1);
      assert.ok(shown[0].to === seats[1] && shown[0].toArea === 1);
      if (grants[index] !== thirdOwners[0]) {
        assert.ok(typeof third[0].ref === "string" && third[0].ref.startsWith("h:"));
        thirdAliases.add(third[0].ref);
        assert.ok(!chainMoves.slice(chainMoves.indexOf(third[0])).some(move => move.ref === thirdRef || move.retired.includes(thirdRef)),
          "third-seat card ID exposed in movement");
      } else assert.equal(third[0].ref, thirdRef);
      if (grants[index] !== shownOwners[0]) assert.ok(typeof shown[0].ref === "string" && shown[0].ref.startsWith("h:"));
      else assert.equal(shown[0].ref, shownRef);
      assert.equal(chainShows.length, 1);
      assert.ok(chainShows[0].source === seats[1] && chainShows[0].refs.length === 1 && chainShows[0].refs[0] === shownRef,
        "public show must identify the direct target's card only");
      const discard = chainMoves.filter(move => move.from === seats[1] && move.fromArea === 1 && move.toArea === 7 && move.ref === shownRef);
      assert.equal(discard.length, 1);
      if (grants[index] !== shownOwners[0]) assert.ok(discard[0].retired.includes(shown[0].ref), "shown-card alias not retired on discard");
      assert.ok(!chainMoves.slice(chainMoves.indexOf(third[0]) + 1).some(move => move.ref === third[0].ref || move.retired.includes(third[0].ref)),
        "third-seat card moved after private grant");
    }
    assert.equal(thirdAliases.size, 2);
    console.log(JSON.stringify({status:'PASS',lane:'chain',privateGrantAudiences:3,distinctOutsiderAliases:2,publicShowAudiences:3,exactDiscardAudiences:3,thirdCardMovementAndShowPrivacy:true}));
  }
  }
  // GameOver precedes the native room's final account updates. Return to the
  // lobby through the normal command before closing the transport.
  await delay(500);
  for (const client of clients) notify(client.socket, "QuitRoom");
  await Promise.all(clients.map(client => client.recorder.wait("EnterLobby")));
  await delay(250);
  function finishWrites(socket) {
    return new Promise<void>((resolve, reject) => {
      const timer = setTimeout(() => reject(Error("socket finish timeout")), 5000);
      socket.end(() => { clearTimeout(timer); resolve(); });
    });
  }
  if (gatewayUrl) {
    // Let the native lobby process each gateway disconnect before closing the
    // next peer, so its departure broadcast can reach the remaining sockets.
    for (const {socket} of clients) {
      await finishWrites(socket);
      await delay(250);
    }
  } else {
    await Promise.all(clients.map(({socket}) => finishWrites(socket)));
  }
  await delay(250);
  console.log(JSON.stringify({status:'PASS',lane,jilixChoices,discardPrompts,showPrompts,playPrompts,gameOverNotifications:playerCount,lobbyReturns:playerCount,writeEnds:playerCount,bounded:true}));
} catch(error) {
  console.log(JSON.stringify({status:'DIAGNOSTIC',errorClass:error.name,category:['native error packet','wire decoder error','timed out waiting for CardWireNegotiated','timed out waiting for Observe','unsupported snapshot CBOR type','fixture socket disconnected','nonempty hands must be observed'].find(x=>String(error.message).includes(x))??'other',locations:String(error.stack).match(/skill-parity-native\.mts:\d+:\d+/g)}));
  process.exitCode=1;
} finally {
  for (const socket of open) socket.destroy();
}
