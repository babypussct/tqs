import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {preview} from 'vite';
import {chromium} from 'playwright-core';
const web=fileURLToPath(new URL('../../',import.meta.url));
const server=await preview({configFile:false,root:web,preview:{host:'127.0.0.1',port:5293,strictPort:true}});
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
 await context.setOffline(true);await page.reload();
 await page.getByRole('heading',{name:/Tam Quốc Sát/}).waitFor();
 await page.getByText('Bạn đang ngoại tuyến. Kết nối mạng để đăng nhập hoặc tiếp tục ván.',{exact:true}).waitFor();
 await page.getByRole('button',{name:'Thử lại',exact:true}).waitFor();
 assert.equal(await page.evaluate(()=>fetch('/gateway/private-cache-test').then(()=>true,()=>false)),false,'private gateway response must not survive offline');
 const output=path.resolve(web,'../../scratch/evidence');fs.mkdirSync(output,{recursive:true});
 await page.screenshot({path:path.join(output,'cp13-pwa-offline.png'),fullPage:true});
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(output,'cp13-pwa-e2e.json'),JSON.stringify({at:new Date().toISOString(),result:'PASS',cachedPaths:cache.requests,scope:'isolated real Chrome service worker install/hash-verified cache/offline reload/status; gateway private fixture not cached; no account or physical installation'},null,2));
 console.log('PASS real Chrome PWA: verified static cache, offline shell/retry/status, no gateway/private cache');
}finally{await browser.close();await new Promise<void>(r=>server.httpServer.close(()=>r()));}
