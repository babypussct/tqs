import test from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';
import { loadUpstreamFiles } from './upstream-packages';

const files = loadUpstreamFiles(fileURLToPath(new URL('../../../scratch/upstream/', import.meta.url)));
test('protected Lua bridge balances stacks across repeated calls, nested UI callbacks and errors', async () => {
  let nested=0;let runtime:LuaRuntime;
  runtime=new LuaRuntime({files,telemetry:true,callbacks:{send:()=>{},setup:()=>{},log:()=>{},ui:command=>{
    if(command==='StackFixture'){assert.equal(runtime.eval('return 7'),7);nested++;}
  }}});
  try {
    await runtime.start();
    const engine=(runtime as unknown as {engine:{global:{getTop():number}}}).engine;
    const top=engine.global.getTop();runtime.eval('collectgarbage("collect")');
    const initial=runtime.eval<number>('return collectgarbage("count")');
    for(let i=0;i<8000;i++) {
      assert.equal(runtime.call('Translate','slash'),'Sát');
      assert.equal(runtime.eval('return 5+2'),7);
      if(i%20===0)runtime.eval('__host_client:notifyUI("StackFixture", {}); return true');
      if(i%100===0)assert.throws(()=>runtime.eval('error("controlled fixture failure")'),/controlled fixture failure/);
      assert.equal(engine.global.getTop(),top,'Lua stack must return to the pre-call boundary');
    }
    runtime.eval('collectgarbage("collect")');
    assert.ok(runtime.eval<number>('return collectgarbage("count")')<initial+1024,'live Lua memory must stay bounded after GC');
    assert.equal(nested,400);
    runtime.sampleTelemetry();
    const metrics=runtime.getTelemetry();
    assert.ok(metrics && metrics.samples.length>=2);
    assert.equal(metrics.callbacksActive,0);
    assert.ok(metrics.callbackCounts.ui>=400 && metrics.callbacksTotal>=400);
    assert.ok(metrics.callbacksPeak>=1);
    assert.ok(metrics.samples.every(s=>s.wasmBytes>0 && s.luaHeapKiB!==null && s.luaHeapKiB>0));
    assert.ok(metrics.samples.every(s=>s.callbacksActive===0));
    assert.ok(metrics.samples.at(-1)!.callbacksTotal>=metrics.samples[0].callbacksTotal);
  } finally {runtime.close();}
});

test('Wasmoon teardown never unrefs the callback coroutine after the owning VM is freed', async () => {
  const runtime = new LuaRuntime({files,callbacks:{send:()=>{},setup:()=>{},ui:()=>{},log:()=>{}}});
  await runtime.start();
  const engine=(runtime as unknown as {engine:{global:{isClosed():boolean;lua:{luaL_unref(...args:unknown[]):void}}}}).engine;
  const state=engine.global;const unref=state.lua.luaL_unref;
  state.lua.luaL_unref=(...args:unknown[])=>{assert.equal(state.isClosed(),false,'must not touch a freed Lua state');unref(...args);};
  runtime.close();assert.equal(state.isClosed(),true);runtime.close();
});

test('large ShowVirtualCard payloads stay bounded when the web reducer ignores them', async () => {
  let received: unknown = null;
  const runtime = new LuaRuntime({files,callbacks:{send:()=>{},setup:()=>{},log:()=>{},ui:(command,data)=>{
    if(command === 'ShowVirtualCard') received = data;
  }}});
  try {
    await runtime.start();
    assert.equal(runtime.eval(`
      local card_payload = string.rep('x', 1100000)
      __host_client:notifyUI('ShowVirtualCard', {card_payload, 17, '', 1})
      return true
    `),true);
    assert.deepEqual(received,{});
  } finally {runtime.close();}
});

test('public UI projection drops private properties and raw move payloads', async () => {
  const events: { command: string; data: unknown }[] = [];
  const runtime = new LuaRuntime({files,callbacks:{send:()=>{},setup:()=>{},log:()=>{},ui:(command,data)=>{
    events.push({command, data});
  }}});
  try {
    await runtime.start();
    // Boot emits translation data; the assertion below covers only this
    // explicit native-style projection sequence.
    events.length = 0;
    assert.equal(runtime.eval(`
      __host_client:notifyUI('PropertyUpdate', {17, 'hp', 3})
      __host_client:notifyUI('PropertyUpdate', {17, 'role', 'lord'})
      __host_client:notifyUI('PropertyUpdate', {17, 'general', 'anjiang'})
      __host_client:notifyUI('PropertyUpdate', {17, 'kingdom', string.rep('x', 200000)})
      __host_client:notifyUI('MoveCards', {merged = {{ids = {1, 2}}}, event_id = 7})
      return true
    `), true);
    assert.deepEqual(events, [
      {command: 'PropertyUpdate', data: [17, 'hp', 3]},
      {command: 'PropertyUpdate', data: [17, 'general', '']},
      {command: 'MoveCards', data: {}},
    ]);
  } finally {runtime.close();}
});


test('reentrant UI queries preserve the calling Lua coroutine stack through GC', async () => {
  let runtime:LuaRuntime;let callbacks=0;let distinct=false;
  runtime=new LuaRuntime({files,callbacks:{send:()=>{},setup:()=>{},log:()=>{},ui:command=>{
    if(command!=='CoroutineFixture')return;
    const vm=runtime as unknown as {engine:{global:{address:number}};callbackThread:{address:number;getTop():number}|null};
    assert.ok(vm.callbackThread,'a host callback must expose its owning Lua thread');
    distinct ||= vm.callbackThread.address!==vm.engine.global.address;
    const top=vm.callbackThread.getTop();
    assert.equal(runtime.call('Translate','slash'),'Sát');
    assert.equal(runtime.eval('return 42'),42);
    assert.equal(vm.callbackThread.getTop(),top);
    callbacks++;
  }}});
  try {
    await runtime.start();
    assert.equal(runtime.eval(`local co=coroutine.create(function()
      for i=1,2000 do
        __host_client:notifyUI("CoroutineFixture", {})
        if i%20==0 then collectgarbage("collect") end
        coroutine.yield(i)
      end
    end)
    for i=1,2000 do local ok,value=coroutine.resume(co); assert(ok and value==i) end
    local ok=coroutine.resume(co);assert(ok);return coroutine.status(co)`),'dead');
    assert.equal(callbacks,2000);assert.ok(distinct,'fixture must exercise a child coroutine rather than only the main state');
  }finally{runtime.close();}
});
