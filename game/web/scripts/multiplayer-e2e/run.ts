/** Two distinct private test accounts, one frozen candidate, real C++ server.
 * Only command/request metadata is persisted; credentials and game payloads stay in memory. */
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { existsSync, readFileSync, writeFileSync, statSync, mkdirSync, cpSync, mkdtempSync, rmSync } from 'node:fs';
import { randomBytes, createHash } from 'node:crypto';
import { loadEnvFile } from 'node:process';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';
import { fileURLToPath } from 'node:url';
import { preview } from 'vite';
import { chromium, type Page } from 'playwright-core';
import { PacketStream, CLIENT_REPLY } from '../../src/engine/packet';

const web = fileURLToPath(new URL('../../',import.meta.url));
const repo = path.resolve(web,'../..');
const config = process.env.TQS_LIVE_CONFIG ?? path.join(os.homedir(),'.codex/secrets/tqs-live-test.env');
assert.equal(statSync(config).mode & 0o077,0,'Private test configuration required');
loadEnvFile(config);
const host=process.env.TQS_LIVE_HOST; assert.ok(host && /^[a-zA-Z0-9.:-]+$/.test(host),'TQS_LIVE_HOST required');
const runtime=process.env.TQS_LIVE_ROOT; assert.ok(runtime && existsSync(path.join(runtime,'flist.txt')));
const first={username:process.env.FK_TEST_USERNAME!,password:process.env.FK_TEST_PASSWORD!};assert.ok(first.username && first.password);
const secondFile=path.join(os.homedir(),'.codex/secrets/tqs-multiplayer-second.json');
if(!existsSync(secondFile)) writeFileSync(secondFile,JSON.stringify({username:`tqsqa${randomBytes(6).toString('hex')}`,
  password:randomBytes(24).toString('hex')}),{mode:0o600,flag:'wx'});
assert.equal(statSync(secondFile).mode & 0o077,0);
const second=JSON.parse(readFileSync(secondFile,'utf8')) as typeof first;
assert.notEqual(first.username,second.username);
const frozenDist = mkdtempSync(path.join(os.tmpdir(),'tqs-frozen-multiplayer-'));
cpSync(path.join(web,'dist'),frozenDist,{recursive:true});
const distIndexSha256 = createHash('sha256').update(readFileSync(path.join(frozenDist,'index.html'))).digest('hex');
const chrome=process.env.TQS_CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
async function freePort(){const s=net.createServer();s.listen(0,'127.0.0.1');await once(s,'listening');const p=(s.address() as net.AddressInfo).port;await new Promise<void>(r=>s.close(()=>r()));return p;}
const [gatewayPort,peerGatewayPort,webPort]=await Promise.all([freePort(),freePort(),freePort()]);
const deploymentUrl = process.env.TQS_LIVE_URL;
const testGatewayRestart = process.argv.includes('--restart-gateway');
assert.ok(!testGatewayRestart || !deploymentUrl,'Gateway restart test requires an isolated local gateway; never restart shared hosting');
if (deploymentUrl) assert.equal(new URL(deploymentUrl).protocol,'https:');
const base=deploymentUrl?.replace(/\/$/,'') ?? `http://127.0.0.1:${webPort}`;
const startGateway=(port=gatewayPort)=>spawn(process.execPath,[path.join(repo,'game/gateway/src/server.mjs')],{
  env:{...process.env,FK_TEST_USERNAME:undefined,FK_TEST_PASSWORD:undefined,FK_ROOT:runtime,FK_HOST:host,
    FK_PORT:process.env.TQS_LIVE_PORT ?? '9527',PORT:String(port),BIND_HOST:'127.0.0.1',ALLOW_ORIGIN:base,TRUSTED_PROXIES:''},stdio:'ignore'});
let gateway=deploymentUrl ? null : startGateway();
const peerGateway=testGatewayRestart ? startGateway(peerGatewayPort) : null;
let server:Awaited<ReturnType<typeof preview>>|undefined;
let browser:Awaited<ReturnType<typeof chromium.launch>>|undefined;
const traces:[{direction:string;command:string;requestId:number;type:number}[],{direction:string;command:string;requestId:number;type:number}[]]=[[],[]];
const errors:string[]=[];let gameStarted=false;let finished=false;
const testRecovery = process.argv.includes('--reconnect') || testGatewayRestart;
const testManual = process.argv.includes('--manual');
let manualCardReply = false;
const candidateId = process.env.TQS_CANDIDATE_ID ?? 'cp08';
assert.match(candidateId,/^cp[0-9]{2}$/);
const errorContexts: unknown[] = [];
let recovered = false;
const pages:Page[]=[];
const currentSockets: unknown[] = [];
const transportOpen = [false,false];
const progressTimer = setInterval(() => console.log(JSON.stringify({stage:finished?'finished':gameStarted?'playing':'login',recovered,
  packets:traces.map(t=>t.length),lastIncoming:traces.map(t=>t.filter(p=>p.direction==='incoming').at(-1)?.command ?? null),errors:errors.length})),60000);
progressTimer.unref();
const testScenario = process.env.TQS_LIVE_SCENARIO ?? (process.argv.includes('--card-chosen') ? 'card-chosen' : '');
assert.ok(testScenario === '' || testScenario === 'card-chosen', 'TQS_LIVE_SCENARIO must be empty or card-chosen');
let scenarioCardChosenReply = false;
async function selectPair(page:Page, preferredLabel?:RegExp){
  const group=page.getByRole('group',{name:'Danh sách võ tướng'});await group.waitFor({timeout:60000});
  const buttons=group.getByRole('button');const n=await buttons.count();
  const order:number[]=[];
  for(let i=0;i<n;i++) {
    const label=await buttons.nth(i).innerText();
    if (preferredLabel?.test(label)) order.unshift(i); else order.push(i);
  }
  for(const a of order){
    const reset=page.getByRole('button',{name:'Chọn lại'});
    if(await reset.isEnabled())await reset.click();
    await buttons.nth(a).click();
    for(const b of order){
      if(a===b)continue;await buttons.nth(b).click();
      if(await page.getByRole('button',{name:'Xác nhận tướng'}).isEnabled()){
        await page.getByRole('button',{name:'Xác nhận tướng'}).click();return;
      }
    }
  }
  throw new Error('No valid native general pair');
}
try{
  const healthDeadline = Date.now() + (deploymentUrl ? 120000 : 10000);
  let healthReady = false;
  while (Date.now() < healthDeadline) {
    if (gateway) assert.equal(gateway.exitCode,null,'Candidate gateway exited');
    try {
      const ready = await fetch(deploymentUrl ? `${base}/gateway/healthz` : `http://127.0.0.1:${gatewayPort}/healthz`,
        { signal: AbortSignal.timeout(Math.min(5000, Math.max(1,healthDeadline-Date.now()))) });
      if (ready.ok && await ready.text()==='ok') { healthReady = true; break; }
    } catch {}
    await new Promise(r=>setTimeout(r, deploymentUrl ? 1000 : 100));
  }
  assert.ok(healthReady,'Candidate health endpoint did not become ready within its bounded startup window');
  if (!deploymentUrl) server=await preview({configFile:false,root:web,build:{outDir:frozenDist},preview:{host:'127.0.0.1',port:webPort,strictPort:true,
    proxy:{'/gateway':{target:`http://127.0.0.1:${gatewayPort}`,ws:true,rewrite:p=>p.replace(/^\/gateway/,'')}}}});
  browser=await chromium.launch({executablePath:chrome,headless:true});
  for(let i=0;i<2;i++){
    const context=await browser.newContext({viewport:{width:390,height:844}});const p=await context.newPage();pages.push(p);
    await p.addInitScript(() => {
      // Opt in to numeric-only WASM/Lua and callback telemetry.
      (window as unknown as { __tqsEnableLuaTelemetry: boolean }).__tqsEnableLuaTelemetry = true;
      const original=console.error;
      const stacks:string[]=[];
      (window as unknown as {__tqsMemoryStacks:string[]}).__tqsMemoryStacks=stacks;
      console.error=(...args:unknown[])=>{
        if(args.some(v=>typeof v==='string' && v.includes('Cannot enlarge memory')))stacks.push(new Error('WASM allocation diagnostic').stack ?? 'no stack');
        original(...args);
      };
    });
    if (testRecovery) await p.addInitScript((peerUrl:string|null) => {
      let active: WebSocket;
      window.WebSocket = new Proxy(window.WebSocket, { construct(Target, args) {
        active = Reflect.construct(Target, peerUrl ? [peerUrl,...args.slice(1)] : args) as WebSocket; return active;
      } });
      (window as unknown as { __tqsTestDisconnect(): void }).__tqsTestDisconnect = () => active.close();
    }, testGatewayRestart && i===1 ? `ws://127.0.0.1:${peerGatewayPort}/ws` : null);
    p.setDefaultTimeout(15000);p.on('pageerror',()=>errors.push(`client-${i+1}: JavaScript error`));
    p.on('console',m=>{if(m.type()==='error'){
      let detail=m.text();for(const value of [first.username,second.username,first.password,second.password])detail=detail.split(value).join('[redacted]');
      errors.push(`client-${i+1}: ${detail.slice(0,1200)}`);
      errorContexts.push({client:i+1,lastIncoming:traces[i].filter(t=>t.direction==='incoming').at(-1)?.command ?? null,location:m.location()});
    }});
    p.on('websocket',ws=>{
      currentSockets[i] = ws; transportOpen[i] = true;
      ws.on('close', () => { if (currentSockets[i] === ws) transportOpen[i] = false; });
      const streams={incoming:new PacketStream(),outgoing:new PacketStream()};
      const record = (direction: 'incoming' | 'outgoing', payload: string | Buffer) => {
        if(typeof payload==='string')return;
        for(const packet of streams[direction].push(payload))traces[i].push({direction,command:packet.command,requestId:packet.requestId,type:packet.type});
      };
      ws.on('framereceived',({payload})=>record('incoming',payload));
      ws.on('framesent',({payload})=>record('outgoing',payload));
    });
    await p.goto(base);await p.getByLabel('Tên tài khoản',{exact:true}).waitFor({timeout:90000});
    const account=i===0?first:second;await p.getByLabel('Tên tài khoản',{exact:true}).fill(account.username);
    await p.getByLabel('Mật khẩu',{exact:true}).fill(account.password);await p.getByRole('button',{name:'Vào sảnh',exact:true}).click();
    await p.getByRole('heading',{name:'Danh sách phòng',exact:true}).waitFor({timeout:60000});
    console.log(`PASS client ${i+1}: distinct account authenticated in real lobby`);
  }
  const roomName=`${candidateId.toUpperCase()} multiplayer ${Date.now()}`;const [a,b]=pages;
  await a.getByLabel('Tên phòng',{exact:true}).fill(roomName);await a.getByLabel('Số người',{exact:true}).selectOption('2');
  await a.getByLabel('Thời gian lượt',{exact:true}).selectOption('60');await a.getByRole('button',{name:'Tạo phòng Quốc Chiến'}).click();
  await a.getByRole('heading',{name:roomName,exact:true}).waitFor();await b.getByRole('button',{name:'Làm mới',exact:true}).click();
  await b.locator('.room-item').filter({hasText:roomName}).getByRole('button',{name:'Vào phòng',exact:true}).click();
  await b.getByRole('heading',{name:roomName,exact:true}).waitFor();
  await Promise.all(pages.map(p=>p.waitForFunction(()=>document.querySelectorAll('.player-item').length===2,null,{timeout:30000})));
  assert.equal(await a.locator('.player-item').count(),2);assert.equal(await b.locator('.player-item').count(),2);
  await b.getByRole('button',{name:'Sẵn sàng',exact:true}).click();await a.getByRole('button',{name:'Bắt đầu',exact:true}).click();gameStarted=true;
  await Promise.all(pages.map((page, index) => selectPair(page,
    testScenario === 'card-chosen' && index === 0 ? /Bàng Đức|庞德|Pangde/i : undefined)));
  for(const p of pages){await p.locator('.game-board').waitFor({timeout:90000});
    await p.waitForFunction(()=>document.querySelectorAll('.board-player').length===2,null,{timeout:30000});
    const opponent=p.locator('.board-player:not(.board-self)');assert.equal(await opponent.count(),1);
    assert.equal(await opponent.locator('[data-card-id], .gameplay-card').count(),0,'opponent hand IDs must not render');}
  console.log('PASS both clients: room/join/ready/StartGame/native general pairs; no opponent card IDs in board DOM');
  if (testManual) {
    await b.getByRole('button',{name:'BOT chơi hộ',exact:true}).click();
    const deadline=Date.now()+180000;
    while(Date.now()<deadline && (!manualCardReply || (testScenario === 'card-chosen' && !scenarioCardChosenReply))) {
      const latest=traces[0].filter(t=>t.direction==='incoming' && (t.type & 0x100)!==0).at(-1);
      if(latest && traces[0].some(t=>t.direction==='outgoing' && t.type===CLIENT_REPLY && t.requestId===latest.requestId)) {
        await new Promise(r=>setTimeout(r,250));continue;
      }
      if(latest?.command==='AskForChoices') {
        const choices=a.getByRole('region',{name:'Lựa chọn trong trận'});
        if(await choices.count()) {
          const option=choices.locator('button.gameplay-choice:enabled:not([aria-pressed="true"])').first();
          if(await option.count())await option.click();
          const confirm=choices.getByRole('button',{name:'Xác nhận lựa chọn',exact:true});
          if(await confirm.count() && await confirm.isEnabled())await confirm.click();
        }
      } else if(latest?.command==='AskForSkillInvoke') {
        const choice=a.locator('.request-panel').getByRole('button',{name:testScenario === 'card-chosen' ? 'Kích hoạt' : 'Hủy',exact:true});
        if(await choice.count() && await choice.isEnabled())await choice.click();
      } else if(latest?.command==='AskForCardChosen') {
        const panel=a.getByRole('region',{name:'Chọn bài đối thủ'});
        const option=panel.locator('button.gameplay-choice:enabled').first();
        if(await option.count())await option.click();
        for(let n=0;n<30;n++) {
          if(traces[0].some(t=>t.direction==='outgoing' && t.type===CLIENT_REPLY && t.requestId===latest.requestId)) {
            scenarioCardChosenReply=true;break;
          }
          await new Promise(r=>setTimeout(r,100));
        }
      } else if(latest?.command==='AskForPoxi') {
        const panel=a.getByRole('region',{name:'Chọn bài đối thủ'});
        const options=panel.locator('button.gameplay-choice:enabled');
        if(await options.count()) {
          await options.first().click();
          const second=panel.locator('button.gameplay-choice:enabled:not([aria-pressed="true"])').first();
          if(await second.count())await second.click();
          const confirm=panel.getByRole('button',{name:'Xác nhận chọn bài',exact:true});
          if(await confirm.count() && await confirm.isEnabled())await confirm.click();
        }
      } else if(latest?.command==='AskForCardsAndChoice') {
        const panel=a.getByRole('region',{name:'Xem bài và chọn phương án'});
        const option=panel.locator('button.gameplay-choice:enabled').first();
        if(await option.count())await option.click();
        const confirm=panel.locator('button.button.primary:enabled').first();
        if(await confirm.count())await confirm.click();
      } else if(latest?.command==='PlayCard') {
        const hand=a.locator('.gameplay-hand button:enabled');
        const preferred:number[]=[];const fallback:number[]=[];
        for(let i=0;i<await hand.count();i++) {
          const label=await hand.nth(i).innerText();
          (testScenario === 'card-chosen' && /Sát|杀|Slash/i.test(label) ? preferred : fallback).push(i);
        }
        for(const i of [...preferred,...fallback]) {
          const card=hand.nth(i);await card.click();
          const target=a.locator('.board-player:not(.board-self) .gameplay-target:enabled');
          if(await target.count() && await target.first().getAttribute('aria-pressed')!=='true')await target.first().click();
          const confirm=a.getByRole('region',{name:'Điều khiển lượt chơi'}).getByRole('button',{name:'Xác nhận',exact:true});
          if(await confirm.count() && await confirm.isEnabled()) {
            await confirm.click();
            for(let n=0;n<30;n++) {
              if(traces[0].some(t=>t.direction==='outgoing' && t.type===CLIENT_REPLY && t.requestId===latest.requestId)){manualCardReply=true;break;}
              await new Promise(r=>setTimeout(r,100));
            }
            if(manualCardReply)break;
          }
          if(await card.count() && await card.getAttribute('aria-pressed')==='true')await card.click();
        }
        if(!manualCardReply) {
          const end=a.getByRole('region',{name:'Điều khiển lượt chơi'}).getByRole('button',{name:'Kết thúc lượt',exact:true});
          if(await end.count() && await end.isEnabled())await end.click();
        }
      }
      await new Promise(r=>setTimeout(r,250));
    }
    assert.ok(manualCardReply,'A native PlayCard must receive one user-selected card/target/OK reply');
    console.log('PASS manual native PlayCard: offered card, Lua-enabled target/OK and one exact client reply');
    if (testScenario === 'card-chosen') {
      assert.ok(scenarioCardChosenReply,'card-chosen scenario must receive and answer AskForCardChosen on the real server');
      console.log('PASS card-chosen scenario: Bàng Đức/jianchu reached AskForCardChosen and received one exact reply');
    }
    const trust=a.getByRole('button',{name:'BOT chơi hộ',exact:true});if(await trust.isVisible())await trust.click();
  } else await Promise.all(pages.map(p=>p.getByRole('button',{name:'BOT chơi hộ',exact:true}).click()));
  if (testRecovery) {
    const recovering = [a];
    if (testGatewayRestart) {
      assert.ok(gateway);
      const exited = once(gateway,'exit');gateway.kill('SIGTERM');await exited;
      gateway=startGateway();
      assert.equal(transportOpen[1],true,'Independent peer must remain connected during restart');
      console.log('Restarted first client gateway process; second peer keeps its separate gateway connection');
    } else await a.evaluate(() => (window as unknown as { __tqsTestDisconnect(): void }).__tqsTestDisconnect());
    for (const p of recovering) {
      const client=pages.indexOf(p);
      await p.waitForFunction(() => document.querySelector('.status')?.textContent === 'Đã kết nối', null, { timeout: 120000 });
      for (let n=0;n<120 && !traces[client].some(t=>t.direction==='incoming' && t.command==='Reconnect');n++)
        await new Promise(resolve=>setTimeout(resolve,500));
      assert.ok(traces[client].some(t=>t.direction==='incoming' && t.command==='Reconnect'),'server must send native Reconnect after transport loss');
      await p.locator('.board-self').waitFor({timeout:30000});
      await p.waitForFunction(()=>document.querySelectorAll('.board-player').length===2,null,{timeout:30000});
      assert.equal(await p.locator('.board-player').count(),2);
      assert.equal(await p.locator('.board-player:not(.board-self) [data-card-id]').count(),0);
      const trust=p.getByRole('button',{name:'BOT chơi hộ',exact:true});if(await trust.isVisible())await trust.click();
    }
    if(testGatewayRestart) {assert.equal(transportOpen[1],true);assert.ok(!traces[1].some(t=>t.direction==='incoming' && t.command==='Reconnect'),'Independent peer must not reconnect');}
    recovered=true;
    console.log(testGatewayRestart ? 'PASS gateway restart: first account reauthenticates/native Reconnect/private board, independent peer stays connected' : 'PASS controlled transport loss: same account automatically authenticates, receives native Reconnect and restores the two-seat board');
  }
  await Promise.all(pages.map(p=>p.getByRole('button',{name:'Về sảnh',exact:true}).waitFor({timeout:900000})));finished=true;
  for(let i=0;i<2;i++){
    assert.ok(traces[i].some(t=>t.direction==='incoming' && t.command==='GameOver'));
    const replies=traces[i].filter(t=>t.direction==='outgoing' && t.type===CLIENT_REPLY);
    assert.equal(new Set(replies.map(t=>t.requestId)).size,replies.length,'one reply per request');
    await pages[i].getByRole('button',{name:'Về sảnh',exact:true}).click();
    await pages[i].getByRole('heading',{name:'Danh sách phòng',exact:true}).waitFor();
    await pages[i].getByRole('button',{name:'Ngắt kết nối',exact:true}).click();
  }
  const out=path.join(repo,'scratch/evidence');mkdirSync(out,{recursive:true});
  writeFileSync(path.join(out,`${candidateId}-${testScenario ? `${testScenario}-` : ''}${testGatewayRestart?'gateway-restart':testRecovery?'reconnect':'multiplayer'}-live-${Date.now()}.json`),JSON.stringify({at:new Date().toISOString(),manualCardReply,scenario:testScenario || null,scenarioCardChosenReply,scope:testGatewayRestart ? 'two real accounts / first client isolated gateway process restart / native Reconnect / independent second gateway peer / Chrome mobile viewports / Trust; no physical device or hosted restart' : testRecovery ? 'two real accounts / controlled WebSocket close / native server Reconnect / Chrome mobile viewports / Trust; no physical network or device' : 'two real accounts / two Chrome mobile viewports / native Trust; no physical device', recovered,gatewayRestart:testGatewayRestart,
    memoryStacks:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsMemoryStacks:string[]}).__tqsMemoryStacks))),
    luaTelemetry:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsLuaTelemetry?:unknown}).__tqsLuaTelemetry ?? null))),
    distIndexSha256,result:errors.length ? 'FAIL' : 'PASS',deploymentUrl:deploymentUrl ?? null,traces,errors,errorContexts},null,2));
  assert.deepEqual(errors,[]);
  console.log('PASS both clients: real GameOver / result / lobby / clean disconnect; sanitized trace saved');
}catch(e){
  console.error('FAIL two-client candidate verification:', (e as Error).message.split(first.username).join('[account]').split(second.username).join('[account]').split(first.password).join('[redacted]').split(second.password).join('[redacted]'));
  const feedback:string[]=[];
  for (const p of pages) {
    for (let message of await p.locator('.error-notice').allTextContents().catch(()=>[])) {
      for (const value of [first.username,second.username,first.password,second.password]) message=message.split(value).join('[redacted]');
      feedback.push(message.slice(0,600));
      console.error('Visible application feedback:',message.slice(0,600));
    }
  }
  const out=path.join(repo,'scratch/evidence');mkdirSync(out,{recursive:true});
  writeFileSync(path.join(out,`reconnect-failure-${Date.now()}.json`),JSON.stringify({at:new Date().toISOString(),result:'FAIL',candidateId,deploymentUrl:deploymentUrl ?? null,feedback,distIndexSha256,recovered,traces,errors,
    memoryStacks:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsMemoryStacks?:string[]}).__tqsMemoryStacks ?? []).catch(()=>[]))),
    luaTelemetry:await Promise.all(pages.map(p=>p.evaluate(()=>(window as unknown as {__tqsLuaTelemetry?:unknown}).__tqsLuaTelemetry ?? null).catch(()=>null))),
    errorContexts,scope:'metadata and numeric heap/callback telemetry only; pending safe GameOver cleanup'},null,2));
  if(gameStarted && !finished){
    console.error('Preserving the connected test browser and candidate processes until GameOver; no forced mid-game disconnect');
    for(const p of pages)await p.getByRole('button',{name:'BOT chơi hộ',exact:true}).click({timeout:3000}).catch(()=>{});
    // GameOver belongs to the shared room. A disconnected participant may never
    // render the result panel, so do not wait forever for that DOM after a failure.
    const backInLobby = (client:number) => {
      const incoming=traces[client].filter(t=>t.direction==='incoming');
      const lastStart=incoming.reduce((last,t,i)=>t.command==='StartGame'?i:last,-1);
      const lastLobby=incoming.reduce((last,t,i)=>t.command==='EnterLobby'?i:last,-1);
      return lastStart>=0 && lastLobby>lastStart;
    };
    while (!traces.some(t=>t.some(p=>p.direction==='incoming' && p.command==='GameOver')) &&
      transportOpen.some((open,i)=>open && !backInLobby(i)))
      await new Promise(resolve=>setTimeout(resolve,1000));
  }
  process.exitCode=1;
}finally{
  clearInterval(progressTimer);
  await browser?.close();await new Promise<void>(resolve=>server?server.httpServer.close(()=>resolve()):resolve());
  gateway?.kill('SIGTERM');peerGateway?.kill('SIGTERM');
  rmSync(frozenDist,{recursive:true,force:true});
}
