import { copyFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const base = resolve(dirname(fileURLToPath(import.meta.url)), '..');
mkdirSync(resolve(base, 'public'), { recursive: true });
copyFileSync(resolve(base, 'node_modules/wasmoon/dist/glue.wasm'), resolve(base, 'public/glue.wasm'));
