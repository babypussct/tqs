import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const dist=path.resolve('dist');
const entries=[];
const walk=dir=>{for(const e of fs.readdirSync(dir,{withFileTypes:true})){
  const file=path.join(dir,e.name);
  if(e.isDirectory())walk(file);
  else if(e.isFile() && e.name!=='sw.js' && /\.(html|js|css|wasm|svg|png|webmanifest)$/.test(e.name))
    entries.push({url:'/'+path.relative(dist,file).split(path.sep).join('/'),sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
}};walk(dist);entries.sort((a,b)=>a.url.localeCompare(b.url));
const version=crypto.createHash('sha256').update(JSON.stringify(entries)).digest('hex');
const worker=`// Generated from this frozen build. Never cache account, game or gateway traffic.
const PREFIX='tqs-shell-';
const CACHE=PREFIX+${JSON.stringify(version)};
const FILES=${JSON.stringify(entries)};
const PATHS=new Set(FILES.map(f=>f.url));
self.addEventListener('install',event=>event.waitUntil((async()=>{
  const cache=await caches.open(CACHE);
  for(const file of FILES){
    const response=await fetch(file.url,{cache:'reload'});
    if(!response.ok || response.type==='opaque')throw new Error('App shell download failed');
    const body=await response.clone().arrayBuffer();
    const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',body)),v=>v.toString(16).padStart(2,'0')).join('');
    if(hash!==file.sha256)throw new Error('App shell hash mismatch');
    await cache.put(file.url,response);
  }
})()));
// Updates wait for existing windows to close; never force activation during a game.
self.addEventListener('activate',event=>event.waitUntil((async()=>{
  for(const key of await caches.keys())if(key.startsWith(PREFIX) && key!==CACHE)await caches.delete(key);
})()));
self.addEventListener('fetch',event=>{
  const request=event.request;const url=new URL(request.url);
  if(request.method!=='GET' || url.origin!==self.location.origin || url.search)return;
  const navigation=request.mode==='navigate' && (url.pathname==='/' || url.pathname==='/index.html');
  if(!navigation && !PATHS.has(url.pathname))return;
  event.respondWith((async()=>{
    const cache=await caches.open(CACHE);
    if(navigation){
      try{const response=await fetch(request);if(response.ok)return response;}catch{}
      const cached=await cache.match('/index.html');
      return cached || Response.error();
    }
    return (await cache.match(url.pathname)) || fetch(request);
  })());
});
`;
fs.writeFileSync(path.join(dist,'sw.js'),worker);
console.log(`Service worker: ${entries.length} verified public files; version ${version.slice(0,12)}; gateway traffic excluded`);
