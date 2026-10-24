import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const dist=path.resolve('dist');
// Hash every emitted public file, with the embedded ID normalized to a token
// to avoid a self-referential hash. Worker/version metadata are derived afterward.
const buildToken='__TQS_BUILD_ID_PLACEHOLDER__';
const stamp=path.join(dist,'.tqs-build-stamp.json');
const {builtAt}=JSON.parse(fs.readFileSync(stamp,'utf8'));
if(typeof builtAt!=='string' || Number.isNaN(Date.parse(builtAt)))throw new Error('Missing build timestamp');
fs.unlinkSync(stamp);
const allFiles=[];
const collect=dir=>{for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
  const file=path.join(dir,entry.name);
  if(entry.isDirectory())collect(file);
  else if(entry.isFile() && !['sw.js','version.json'].includes(path.relative(dist,file)))allFiles.push(file);
}};
collect(dist);allFiles.sort();
const digest=crypto.createHash('sha256');
for(const file of allFiles){digest.update(path.relative(dist,file).split(path.sep).join('/'));digest.update('\0');digest.update(fs.readFileSync(file));digest.update('\0');}
const buildId=digest.digest('hex');
for(const file of allFiles)if(/\.(js|html)$/.test(file)){
  const source=fs.readFileSync(file,'utf8');
  if(source.includes(buildToken))fs.writeFileSync(file,source.replaceAll(buildToken,buildId));
}
const clientSource=fs.readFileSync(new URL('../src/system/clientVersion.ts',import.meta.url),'utf8');
const clientVersion=/CLIENT_VERSION = '([^']+)'/.exec(clientSource)?.[1];
if(!clientVersion)throw new Error('Missing client version');
fs.writeFileSync(path.join(dist,'version.json'),JSON.stringify({version:clientVersion,buildId,swVersion:buildId,builtAt},null,2)+'\n');
const entries=[];
const walk=dir=>{for(const e of fs.readdirSync(dir,{withFileTypes:true})){
  const file=path.join(dir,e.name);
  if(e.isDirectory())walk(file);
  else if(e.isFile() && e.name!=='sw.js' && /\.(html|js|css|wasm|svg|png|webmanifest)$/.test(e.name))
    entries.push({url:'/'+path.relative(dist,file).split(path.sep).join('/'),sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
}};walk(dist);entries.sort((a,b)=>a.url.localeCompare(b.url));
const version=buildId;
const worker=`// Generated from this frozen build. Never cache account, game or gateway traffic.
const PREFIX='tqs-shell-';
const CACHE=PREFIX+${JSON.stringify(version)};
const FILES=${JSON.stringify(entries)};
const PATHS=new Set(FILES.map(f=>f.url));
async function warmShell(){
  const cache=await caches.open(CACHE);
  for(let offset=0;offset<FILES.length;offset+=6)await Promise.all(FILES.slice(offset,offset+6).map(async file=>{
    const response=await fetch(file.url,{cache:'reload'});
    if(!response.ok || response.type==='opaque')throw new Error('App shell download failed');
    const body=await response.clone().arrayBuffer();
    const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',body)),v=>v.toString(16).padStart(2,'0')).join('');
    if(hash!==file.sha256)throw new Error('App shell hash mismatch');
    await cache.put(file.url,response);
  }));
}
self.addEventListener('install',event=>event.waitUntil(warmShell()));
// Activation is requested only by the update guard outside an active match.
self.addEventListener('message',event=>{
  if(event.data?.type==='SKIP_WAITING')event.waitUntil(self.skipWaiting());
  if(event.data?.type==='REFRESH_SHELL')event.waitUntil(warmShell().then(
    ()=>event.ports[0]?.postMessage({ok:true}),
    ()=>event.ports[0]?.postMessage({ok:false})
  ));
});
self.addEventListener('activate',event=>event.waitUntil((async()=>{
  for(const key of await caches.keys())if(key.startsWith(PREFIX) && key!==CACHE)await caches.delete(key);
  await self.clients.claim();
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
