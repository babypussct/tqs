import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const [runtimeArg, outputArg] = process.argv.slice(2);
if (!runtimeArg || !outputArg) throw new Error('Usage: node deploy/mobile/package-release.mjs /pinned/runtime /new/release-directory');
const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const runtime = path.resolve(runtimeArg); const output = path.resolve(outputArg);
if (fs.existsSync(output)) throw new Error('Release directory must be new; never overwrite an existing release');
const flist = fs.readFileSync(path.join(runtime, 'flist.txt'));
const dist = path.join(repo,'game/web/dist');
if (!fs.existsSync(path.join(dist,'index.html'))) throw new Error('Build web first');
fs.mkdirSync(output,{recursive:true});
const copyTree = (src,dst,filter) => {
  fs.mkdirSync(dst,{recursive:true});
  for (const entry of fs.readdirSync(src,{withFileTypes:true})) {
    if (entry.isSymbolicLink()) throw new Error(`Symlink excluded from release: ${entry.name}`);
    if (!filter(entry.name,entry.isDirectory())) continue;
    if (entry.isDirectory()) copyTree(path.join(src,entry.name),path.join(dst,entry.name),filter);
    else if (entry.isFile()) fs.copyFileSync(path.join(src,entry.name),path.join(dst,entry.name));
  }
};
copyTree(dist,path.join(output,'dist'),()=>true);
copyTree(path.join(runtime,'packages'),path.join(output,'runtime/packages'),name=>!['.git','node_modules'].includes(name) && !name.startsWith('.env'));
fs.writeFileSync(path.join(output,'runtime/flist.txt'),flist);
for (const name of ['package.json','package-lock.json']) {
  fs.mkdirSync(path.join(output,'gateway'),{recursive:true});
  fs.copyFileSync(path.join(repo,'game/gateway',name),path.join(output,'gateway',name));
}
copyTree(path.join(repo,'game/gateway/src'),path.join(output,'gateway/src'),()=>true);
for (const name of ['Dockerfile.gateway','Dockerfile.render','compose.yaml','Caddyfile','env.example','render.yaml'])
  fs.copyFileSync(path.join(repo,'deploy/mobile',name),path.join(output,name));
const files={};
const walk=dir=>{for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);
  if(e.isDirectory())walk(p);else files[path.relative(output,p).split(path.sep).join('/')]=crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');}};
walk(output);
fs.writeFileSync(path.join(output,'RELEASE.json'),JSON.stringify({createdAt:new Date().toISOString(),runtimeMD5:crypto.createHash('md5').update(flist).digest('hex'),files},null,2)+'\n');
console.log(`Packaged ${Object.keys(files).length} files; release manifest created`);
