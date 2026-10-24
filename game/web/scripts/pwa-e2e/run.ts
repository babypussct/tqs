import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {preview} from 'vite';
import {chromium} from 'playwright-core';
const web=fileURLToPath(new URL('../../',import.meta.url));
const server=await preview({configFile:false,root:web,preview:{host:'127.0.0.1',port:5293,strictPort:true}});
const workerFile=path.join(web,'dist/sw.js');
const originalWorker=fs.readFileSync(workerFile,'utf8');
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
 assert.ok(cache.requests.includes('/icon-192.png'));assert.ok(!cache.requests.some(p=>p.startsWith('/gateway/')));
 await page.unroute('**/gateway/private-cache-test');
 // A real waiting worker must open the update gate; reset keeps unrelated cache/Auth IndexedDB.
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
 fs.writeFileSync(workerFile,originalWorker.replace(/const CACHE=PREFIX\+([^;]+);/,'const CACHE=PREFIX+$1+"-upgrade-fixture";'));
 await page.evaluate(async()=>{await (await navigator.serviceWorker.ready).update();});
 await page.getByRole('dialog',{name:'Cần cập nhật chiến trường',exact:true}).waitFor({timeout:60000});
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
 assert.ok(upgradedKeys.some(k=>k.endsWith('-upgrade-fixture')));
 assert.ok(!upgradedKeys.includes(cache.keys[0]),'old shell removed');
 await context.setOffline(true);await page.reload();
 await page.getByRole('heading',{name:/Tam Quốc Sát/}).waitFor();
 await page.getByText('Bạn đang ngoại tuyến. Kết nối mạng để đăng nhập hoặc tiếp tục ván.',{exact:true}).waitFor();
 await page.getByRole('button',{name:'Thử lại',exact:true}).waitFor();
 assert.equal(await page.evaluate(()=>fetch('/gateway/private-cache-test').then(()=>true,()=>false)),false,'private gateway response must not survive offline');
 const output=path.resolve(web,'../../scratch/evidence');fs.mkdirSync(output,{recursive:true});
 await page.screenshot({path:path.join(output,'cp13-pwa-offline.png'),fullPage:true});
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(output,'cp13-pwa-e2e.json'),JSON.stringify({at:new Date().toISOString(),result:'PASS',cachedPaths:cache.requests,scope:'isolated Chrome: normalized full-build identity, verified install, real waiting-worker gate/activation, shell purge/rebuild, IndexedDB sentinel/unrelated cache preserved, offline reload, private traffic excluded; no real Google account or physical device'},null,2));
 console.log('PASS real Chrome PWA: verified install, waiting-worker gate, activation, shell refresh, preserved IndexedDB/unrelated cache, offline reload, no private cache');
}finally{fs.writeFileSync(workerFile,originalWorker);await browser.close();await new Promise<void>(r=>server.httpServer.close(()=>r()));}
