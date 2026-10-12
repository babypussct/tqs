import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
const root=path.resolve(process.argv[2] ?? '');
if(!process.argv[2])throw new Error('Usage: node deploy/mobile/verify-release.mjs /release');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'RELEASE.json'),'utf8'));
const actual=[];
const walk=dir=>{for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
  const p=path.join(dir,entry.name);
  if(entry.isSymbolicLink())throw new Error('Release contains a symlink');
  if(entry.isDirectory())walk(p);else if(entry.isFile() && p!==path.join(root,'RELEASE.json'))actual.push(path.relative(root,p).split(path.sep).join('/'));
}};
walk(root);
if(JSON.stringify(actual.sort())!==JSON.stringify(Object.keys(manifest.files).sort()))throw new Error('Release inventory mismatch');
for(const [name,hash] of Object.entries(manifest.files)){
  const file=path.resolve(root,name);
  if(!file.startsWith(root+path.sep))throw new Error('Invalid manifest path');
  if(crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')!==hash)throw new Error(`Hash mismatch: ${name}`);
}
if(crypto.createHash('md5').update(fs.readFileSync(path.join(root,'runtime/flist.txt'))).digest('hex')!==manifest.runtimeMD5)throw new Error('Runtime MD5 mismatch');
console.log(`PASS release verification: ${Object.keys(manifest.files).length} files`);
