// Generated from this frozen build. Never cache account, game or gateway traffic.
const PREFIX='tqs-shell-';
const CACHE=PREFIX+"893a421c4bbbf3c7bcf113d719d8a1d713327285cef5ad4300280494ccec6a9f";
const FILES=[{"url":"/apple-touch-icon.png","sha256":"c70ec8565fc9b2b2fc15c40754a32fdf8063a07dc66c7f766b05b0d34698ea13"},{"url":"/assets/index-Bhrngiws.css","sha256":"66a624ff7b3b66c7c6cd00d7f366535d5257d54059109ab33e5278848e890940"},{"url":"/assets/index-DmvTOScR.js","sha256":"3bfe52b9f37d60b15ac7809a989a5b4c10af9792f30203f7588efce80e83c4c4"},{"url":"/favicon.svg","sha256":"18030e5530de7ce8b1bce387a99765b6c461add5ab4bbbd3439b40dd575711e2"},{"url":"/glue.wasm","sha256":"95f3f19ddb740125883bc41d5ec670cd0828e7b58c8bdad385323cbff497b55c"},{"url":"/icon-192.png","sha256":"6c319cad5077f1d59b7891a4c38f80af8fc45243651bbafe53e1e3277cb2265f"},{"url":"/icon-512.png","sha256":"6fb9c9ccbec4741e5ba5bd80ff6c10e010298a91137553c1075001bf23379284"},{"url":"/index.html","sha256":"e3445a6cc788beb351bff4e0737a38b6da72eeb352fd32f359f2a17b369183d0"},{"url":"/manifest.webmanifest","sha256":"5ba6271e4edea181de440a7ec869eebec116f42e3424114babe2d0b8253d5b5e"}];
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
