import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {preview} from 'vite';
import {chromium} from 'playwright-core';
const web=fileURLToPath(new URL('../../',import.meta.url));
const server=await preview({configFile:false,root:web,
 plugins:[{name:'pages-canonical-html-fixture',configurePreviewServer(server){
  server.middlewares.use((request,response,next)=>{
   if(request.url!=='/index.html')return next();
   response.writeHead(301,{Location:'/'});response.end();
  });
 }}],preview:{host:'127.0.0.1',port:5293,strictPort:true}});
const workerFile=path.join(web,'dist/sw.js');
const originalWorker=fs.readFileSync(workerFile,'utf8');
const fixtureBackups = new Map<string, Buffer>();
function writeFixture(file: string, bytes: string | Buffer) {
 if (!fixtureBackups.has(file)) fixtureBackups.set(file, fs.readFileSync(file));
 fs.writeFileSync(file, bytes);
}
const build=JSON.parse(fs.readFileSync(path.join(web,'dist/version.json'),'utf8'));
assert.equal(build.version,'0.5.25');assert.equal(build.swVersion,build.buildId);
const files: string[]=[];
const collect=(dir:string)=>{for(const e of fs.readdirSync(dir,{withFileTypes:true})){
 const file=path.join(dir,e.name);if(e.isDirectory())collect(file);
 else if(e.isFile() && !['sw.js','version.json'].includes(path.relative(path.join(web,'dist'),file)))files.push(file);
}};collect(path.join(web,'dist'));files.sort();
const digest=createHash('sha256');
for(const file of files){
 let bytes=fs.readFileSync(file);
 if(/\.(js|html)$/.test(file))bytes=Buffer.from(bytes.toString().replaceAll(build.buildId,'__TQS_BUILD_ID_PLACEHOLDER__'));
 digest.update(path.relative(path.join(web,'dist'),file).split(path.sep).join('/'));digest.update('\0');digest.update(bytes);digest.update('\0');
}
assert.equal(digest.digest('hex'),build.buildId,'embedded ID matches normalized full dist hash');
const workerFiles=JSON.parse(/const FILES=(.*);/.exec(originalWorker)![1]) as {url:string;sha256:string}[];
for(const file of workerFiles)assert.equal(createHash('sha256').update(fs.readFileSync(path.join(web,'dist',file.url))).digest('hex'),file.sha256);
assert.ok(files.some(file=>file.endsWith('.js') && fs.readFileSync(file,'utf8').includes(build.buildId)));
assert.ok(!workerFiles.some(file=>file.url==='/version.json'));
assert.ok(!files.some(file=>file.endsWith('.tqs-build-stamp.json')));
assert.ok(files.some(file=>file.endsWith('.js') && fs.readFileSync(file,'utf8').includes(build.builtAt)), 'timestamp included before Vite hashes the entry filename');
const browser=await chromium.launch({executablePath:process.env.TQS_CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
try {
 const context=await browser.newContext({viewport:{width:390,height:844}});const page=await context.newPage();
 const errors:string[]=[];page.on('pageerror',e=>errors.push(e.name));
 await page.goto('http://127.0.0.1:5293/');
 await page.evaluate(()=>navigator.serviceWorker.ready.then(()=>true));
 await page.reload();
 await page.waitForFunction(()=>!!navigator.serviceWorker.controller);
 assert.equal(await page.getByRole('heading',{name:/Tam Quốc Sát/}).count(),1);
 await page.route('**/gateway/private-cache-test',route=>route.fulfill({status:200,contentType:'application/json',body:'{"private":"never-cache-fixture"}'}));
 assert.equal(await page.evaluate(()=>fetch('/gateway/private-cache-test').then(r=>r.json()).then(d=>d.private)),'never-cache-fixture');
 const cache=await page.evaluate(async()=>{
  const keys=(await caches.keys()).filter(k=>k.startsWith('tqs-shell-'));const requests=[];
  for(const key of keys)for(const request of await (await caches.open(key)).keys())requests.push(new URL(request.url).pathname);
  return {keys,requests};
 });
 assert.equal(cache.keys.length,1);assert.ok(cache.requests.includes('/index.html'));
 assert.equal(await page.evaluate(async()=>{
   const key=(await caches.keys()).find(k=>k.startsWith('tqs-shell-'))!;
   return (await (await caches.open(key)).match('/index.html'))?.redirected;
 }),true,'fixture reproduces Pages /index.html canonical redirect');
 assert.ok(cache.requests.includes('/icon-192.png'));assert.ok(!cache.requests.some(p=>p.startsWith('/gateway/')));
 await page.unroute('**/gateway/private-cache-test');
 // Keep unrelated cache/Auth IndexedDB through same-build and genuine-update workers.
 await page.evaluate(async()=>{
   await (await caches.open('tqs-unrelated-fixture')).put('/preserve',new Response('keep'));
   await new Promise<void>((resolve,reject)=>{
     const request=indexedDB.open('tqs-firebase-auth-fixture',1);
     request.onupgradeneeded=()=>request.result.createObjectStore('auth');
     request.onerror=()=>reject(request.error);
     request.onsuccess=()=>{const db=request.result;const tx=db.transaction('auth','readwrite');
       tx.objectStore('auth').put('signed-in-fixture','session');tx.oncomplete=()=>{db.close();resolve();};};
   });
 });
 // Different worker bytes/cache state alone must not claim a new web release.
 writeFixture(workerFile,originalWorker.replace(/const CACHE=PREFIX\+([^;]+);/,'const CACHE=PREFIX+$1+"-same-build-fixture";'));
 const sameBuildCheck = page.waitForResponse(r => new URL(r.url()).pathname === '/version.json');
 await page.evaluate(async()=>{await (await navigator.serviceWorker.ready).update();});
 await page.waitForFunction(async()=>!!(await navigator.serviceWorker.ready).waiting);
 await (await sameBuildCheck).finished();
 await page.evaluate(()=>new Promise<void>(resolve=>requestAnimationFrame(()=>requestAnimationFrame(()=>resolve()))));
 assert.equal(await page.getByRole('dialog',{name:'Cần cập nhật chiến trường',exact:true}).count(),0,
   'same build with a waiting worker must not force an update');
 // Stage a second, coherent build: new JS bytes, normalized full-build ID,
 // embedded runtime ID, metadata, cache name and verified shell hashes.
 const entry=files.find(file=>file.endsWith('.js') && fs.readFileSync(file,'utf8').includes(build.buildId))!;
 writeFixture(entry,fs.readFileSync(entry,'utf8')+'\n// PWA next release fixture\n');
 const nextDigest=createHash('sha256');
 for(const file of files){
   let bytes=fs.readFileSync(file);
   if(/\.(js|html)$/.test(file))bytes=Buffer.from(bytes.toString().replaceAll(build.buildId,'__TQS_BUILD_ID_PLACEHOLDER__'));
   nextDigest.update(path.relative(path.join(web,'dist'),file).split(path.sep).join('/'));nextDigest.update('\0');nextDigest.update(bytes);nextDigest.update('\0');
 }
 const nextId=nextDigest.digest('hex');assert.notEqual(nextId,build.buildId);
 for(const file of files)if(/\.(js|html)$/.test(file)){
   const source=fs.readFileSync(file,'utf8');
   if(source.includes(build.buildId))writeFixture(file,source.replaceAll(build.buildId,nextId));
 }
 writeFixture(path.join(web,'dist/version.json'),JSON.stringify({...build,buildId:nextId,swVersion:nextId}));
 const nextFiles=workerFiles.map(file=>({...file,sha256:createHash('sha256').update(fs.readFileSync(path.join(web,'dist',file.url))).digest('hex')}));
 writeFixture(workerFile,originalWorker.replace('const CACHE=PREFIX+'+JSON.stringify(build.buildId),
   'const CACHE=PREFIX+'+JSON.stringify(nextId)).replace(/const FILES=.*;/,'const FILES='+JSON.stringify(nextFiles)+';'));
 await page.evaluate(async()=>{await (await navigator.serviceWorker.ready).update();});
 const updateDialog=page.getByRole('dialog',{name:'Cần cập nhật chiến trường',exact:true});
 await updateDialog.waitFor({timeout:60000});
 const labels=await updateDialog.locator('strong').allTextContents();
 assert.equal(labels.length,2);assert.notEqual(labels[0],labels[1]);
 assert.ok(labels[0].includes(build.buildId.slice(0,12)) && labels[1].includes(nextId.slice(0,12)));
 const updateEvidence=path.resolve(web,'../../scratch/evidence/update-version-logic-20261025');
 fs.mkdirSync(updateEvidence,{recursive:true});
 for(const viewport of [{width:320,height:568},{width:844,height:390},{width:1280,height:800}]){
   await page.setViewportSize(viewport);
   await page.evaluate(()=>new Promise<void>(resolve=>requestAnimationFrame(()=>requestAnimationFrame(()=>resolve()))));
   const box=await updateDialog.boundingBox();
   assert.ok(box && box.x>=0 && box.y>=0 && box.x+box.width<=viewport.width && box.y+box.height<=viewport.height);
   await page.screenshot({path:path.join(updateEvidence,`update-different-build-${viewport.width}x${viewport.height}.png`)});
 }
 await page.setViewportSize({width:390,height:844});
 const reloaded=page.waitForNavigation({waitUntil:'load',timeout:90000});
 await page.getByRole('button',{name:'Cập Nhật Ngay',exact:true}).click();
 await reloaded;
 await page.waitForFunction(()=>!location.search.includes('tqs-update'));
 await page.waitForFunction(()=>!!navigator.serviceWorker.controller);
 assert.equal(await page.getByRole('dialog',{name:'Cần cập nhật chiến trường',exact:true}).count(),0);
 assert.equal(await page.evaluate(async()=>await (await caches.open('tqs-unrelated-fixture')).match('/preserve').then(r=>r?.text())),'keep');
 assert.equal(await page.evaluate(()=>new Promise((resolve,reject)=>{
   const r=indexedDB.open('tqs-firebase-auth-fixture');r.onerror=()=>reject(r.error);
   r.onsuccess=()=>{const db=r.result;const get=db.transaction('auth').objectStore('auth').get('session');
     get.onsuccess=()=>{db.close();resolve(get.result);};};
 })),'signed-in-fixture');
 const upgradedKeys=await page.evaluate(()=>caches.keys());
 assert.ok(upgradedKeys.includes('tqs-shell-'+nextId));
 assert.ok((await page.locator('.tqs-version').innerText()).includes(nextId.slice(0,4)));
 assert.ok(!upgradedKeys.some(k=>k.endsWith('-same-build-fixture')));
 assert.ok(!upgradedKeys.includes(cache.keys[0]),'old shell removed');
 await context.setOffline(true);await page.reload();
 await page.getByRole('heading',{name:/Tam Quốc Sát/}).waitFor();
 await page.getByText('Bạn đang ngoại tuyến. Kết nối mạng để đăng nhập hoặc tiếp tục ván.',{exact:true}).waitFor();
 await page.getByRole('button',{name:'Thử lại',exact:true}).waitFor();
 assert.equal(await page.evaluate(()=>fetch('/gateway/private-cache-test').then(()=>true,()=>false)),false,'private gateway response must not survive offline');
 const output=path.resolve(web,'../../scratch/evidence');fs.mkdirSync(output,{recursive:true});
 await page.screenshot({path:path.join(output,'cp13-pwa-offline.png'),fullPage:true});
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(output,'cp13-pwa-e2e.json'),JSON.stringify({at:new Date().toISOString(),result:'PASS',cachedPaths:cache.requests,scope:'isolated Chrome: normalized full-build identity, verified install, same-build waiting-worker suppression and distinct-build gate/activation, shell purge/rebuild, IndexedDB sentinel/unrelated cache preserved, offline reload, private traffic excluded; no real Google account or physical device'},null,2));
 console.log('PASS real Chrome PWA: verified install, same-build waiting worker ignored, distinct-build labels/gate, activation, shell refresh, preserved IndexedDB/unrelated cache, offline reload, no private cache');
}finally{for(const [file,bytes] of fixtureBackups)fs.writeFileSync(file,bytes);fs.writeFileSync(workerFile,originalWorker);await browser.close();await new Promise<void>(r=>server.httpServer.close(()=>r()));}
