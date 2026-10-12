import assert from 'node:assert/strict';
import { test } from 'node:test';
import { parseNativeDialog, movedRows } from '../src/engine/nativeDialogs';
import { GameConnection, type SocketHandlers } from '../src/engine/connection';
import { PacketType, encodePacket } from '../src/engine/packet';

const payload = {cards:[[1,2],[3]],names:['Top','Bottom'], capacities:[2,2],limits:[0,0],
  is_free:false,pattern:'.',poxi_type:'',cancelable:false};
test('native arrangement keeps each card once and swaps full groups without exposing IDs',()=>{
  const dialog = parseNativeDialog('AskForArrangeCards',payload,id=>({name:`card-${id}`,number:5}))!;
  const [a,b,c] = dialog.prompt.cards.map(card=>card.token);
  assert.equal(movedRows(dialog,a,0,2),null,'fixed first row cannot be reordered');
  assert.deepEqual(movedRows(dialog,c,0,0),[[3,2],[1]]);
  assert.deepEqual(movedRows(dialog,a,1,1),[[2],[3,1]]);
  for(const card of dialog.prompt.cards) assert.equal('id' in card,false);
  assert.equal(movedRows(dialog,b,9,0),null);assert.equal(movedRows(dialog,'forged',1,0),null);
  for(const patch of [{cards:[[1],[1]]},{capacities:[0],limits:[1]},{cards:[[1,-2]]}])
    assert.equal(parseNativeDialog('AskForArrangeCards',{...payload,...patch},()=>null),null);
});
test('native dialog reply never survives reentrant request replacement or disconnect',()=>{
  for(const replacement of ['disconnect','same-id']) {
    let handlers!:SocketHandlers;let reenter=false;const sent:Uint8Array[]=[];
    const conn=new GameConnection({files:new Map(),username:'fixture',password:'fixture',md5:'fixture',uuid:'fixture',
      openSocket:h=>{handlers=h;return {send:b=>sent.push(b),close:()=>{}}},onUi:()=>{},
      onRequest:r=>{if(!r && reenter){reenter=false;if(replacement==='disconnect') handlers.onClose('fixture');else receive();}}});
    conn.connect();conn['setStatus']({kind:'online'});
    conn.lua.receive=()=>conn['handleLuaUi']('AskForAG',[[1,2],true,'']);
    conn.lua.call=<T>(name:string):T=>{if(name==='__web_reply_hex')return '01' as T;
      if(name==='__web_reply')conn['sendFromLua']('reply','','01');return undefined as T};
    const receive=()=>handlers.onData(encodePacket({requestId:1,type:PacketType.REQUEST|PacketType.SRC_SERVER|PacketType.DEST_CLIENT,
      command:'AskForAG',data:new Uint8Array(),timeout:30,timestamp:Date.now()}));
    receive();const token=conn['pendingRequest']!.nativeDialogPrompt!.cards[0].token;
    reenter=true;assert.throws(()=>conn.respondToNativeDialog(1,token),/chưa đến máy chủ/);
    assert.equal(sent.length,0);if(replacement==='same-id')assert.throws(()=>conn.respondToNativeDialog(1,token),/không hợp lệ/);
  }
});

test('expired native dialogs clear their private state before rejecting a reply', () => {
  let handlers!: SocketHandlers;
  const requests: (number | null)[] = [];
  const conn = new GameConnection({files: new Map(), username: 'fixture', password: 'fixture', md5: 'fixture', uuid: 'fixture',
    openSocket: h => { handlers = h; return {send: () => {}, close: () => {}}; }, onUi: () => {},
    onRequest: request => requests.push(request?.requestId ?? null)});
  conn.connect(); conn['setStatus']({kind: 'online'});
  conn.lua.receive = () => conn['handleLuaUi']('AskForAG', [[1], true, '']);
  conn.lua.call = <T>(): T => null as T;
  handlers.onData(encodePacket({requestId: 7,
    type: PacketType.REQUEST | PacketType.SRC_SERVER | PacketType.DEST_CLIENT,
    command: 'AskForAG', data: new Uint8Array(), timeout: 30, timestamp: Date.now()}));
  conn['pendingRequest']!.expiresAt = Date.now() - 1;
  const token = conn['pendingRequest']!.nativeDialogPrompt!.cards[0].token;
  assert.throws(() => conn.respondToNativeDialog(7, token), /hết thời gian/);
  assert.equal(conn['pendingRequest'], null);
  assert.equal(conn['nativeDialog'], null);
  assert.equal(requests.at(-1), null);
});


test('optional native AG cancelable nil preserves numeric-key CBOR maps and forbids cancellation',()=>{
  const dialog=parseNativeDialog('AskForAG',{'1':[4,5],'3':'amazing_grace'},()=>null)!;
  assert.equal(dialog.prompt.cancelable,false);assert.equal(dialog.prompt.cards.length,2);
  assert.equal(parseNativeDialog('AskForAG',[[4,5]],()=>null)!.prompt.cancelable,false);
});

test('ChooseSkill accepts only the pinned component, bounded distinct options and valid native counts', () => {
  const prop = { skills: ['huoshui','qingcheng'], min: 1, max: 1, prompt: '', cancelable: true };
  const payload = (changes = {}, url = 'packages/utility/qml/ChooseSkillBox.qml') => ({ component: { url,
    model: { url: 'packages/utility/qml/models/ChooseSkillModel.qml', prop: {...prop,...changes} } } });
  const dialog = parseNativeDialog('CustomDialog', payload(), () => { throw new Error('Skill options must never query card faces'); });
  assert.equal(dialog?.prompt.kind,'skills');assert.equal(dialog?.prompt.cancelable,true);
  assert.equal(parseNativeDialog('CustomDialog',payload({skills:['huoshui','huoshui']}),()=>null),null);
  assert.equal(parseNativeDialog('CustomDialog',payload({min:2,max:1}),()=>null),null);
  assert.equal(parseNativeDialog('CustomDialog',payload({max:3}),()=>null),null);
  assert.equal(parseNativeDialog('CustomDialog',payload({},'untrusted.qml'),()=>null),null);
});

test('native parser rejects duplicate KnownBoth options and contains face-provider failures', () => {
  const duplicate = { component: { url: 'packages/hegemony/qml/KnownBothBox.qml',
    model: { url: 'packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml',
      prop: { cards: ['zoushi', 'zoushi'], min: 0, max: 0, prompt: '', ok_options: ['OK'], cancel_options: [] } } } };
  assert.equal(parseNativeDialog('CustomDialog', duplicate, () => null), null);
  const dialog = parseNativeDialog('AskForAG', [[1, 2], false, ''], () => { throw new Error('malformed face'); });
  assert.ok(dialog);
  assert.equal(dialog.prompt.cards[0].name, undefined);
});

test('native private dialog metadata stays bounded before Lua rule callbacks', () => {
  const base: unknown[] = [['general-a', 'general-b'], 1, null, null, 'rule', 'Choose', { ok: true }];
  assert.ok(parseNativeDialog('AskForGeneral', base, () => null));
  assert.equal(parseNativeDialog('AskForGeneral', [...base.slice(0, 6), { blob: 'x'.repeat(70_000) }], () => null), null);
  const cyclic: Record<string, unknown> = {}; cyclic.self = cyclic;
  assert.equal(parseNativeDialog('AskForGeneral', [...base.slice(0, 6), cyclic], () => null), null);
});
