import { defineConfig, type Plugin } from 'vite';
import react from '@vitejs/plugin-react';
import { generateKeyPairSync } from 'node:crypto';
import path from 'node:path';
import fs from 'node:fs';
import { zipSync } from 'fflate';
import { BASELINE_PACKAGE_NAMES, loadUpstreamFiles } from './scripts/upstream-packages';

const runtimeRoot = path.resolve(__dirname, '../../runtime');
const cardCatalogPath = path.resolve(__dirname, 'public/quoc-chien-card-inventory.json');
const localCatalogArtRoot = path.resolve(__dirname, 'card-catalog-sources');
const nativeCardAssetPaths = [
  'packages/mobile/image/card/ex_eight_diagram.png',
  'packages/mobile/image/card/ex_crossbow.png',
  'packages/mobile/image/card/ex_nioh_shield.png',
  'packages/mobile/image/card/ex_silver_lion.png',
  'packages/mobile/image/card/ex_vine.png',
  'packages/mobile/image/card/xuanjian_sword.png',
  'packages/gamemode/image/card/v33__ex_nihilo.png',
  'packages/gamemode/image/card/v11__dismantlement.png',
  'packages/gamemode/image/card/ice__slash.png',
  'packages/gamemode/image/card/stab__slash.png',
  'packages/gamemode/image/card/yitian_sword.png',
  'packages/gamemode/image/card/five_elements_fan.png',
  'packages/gamemode/image/card/seven_stars_sword.png',
  'packages/gamemode/image/card/crafty_escape.png',
  'packages/gamemode/image/card/honey_trap.png',
  'packages/gamemode/image/card/drowning.png',
  'packages/tenyear/image/card/thunder_blade.png',
  'packages/tenyear/image/card/quenched_blade.png',
  'packages/tenyear/image/card/real__crossbow.png',
  'packages/tenyear/image/card/red_spear.png',
  'packages/tenyear/image/card/water_sword.png',
  'packages/tenyear/image/card/poisonous_dagger.png',
  'packages/standard_ex/image/card/role__wooden_ox.png',
  'packages/overseas/image/card/moon_spear.png',
  'packages/overseas/image/card/celestial_calabash.png',
  'packages/overseas/image/card/talisman.png',
  'packages/sp/image/card/delayedTrick/yanxiao_trick.png',
];
const upstreamRoot = path.resolve(__dirname, '../../scratch/upstream');

const RUNTIME_MEDIA_ROOTS = [
  'image/card',
  'audio/card',
  'image/anim',
] as const;

/** Keep the browser's package resolver in lockstep with the checked-in runtime media. */
function collectRuntimeMediaAssetPaths(): string[] {
  const packagesRoot = path.join(runtimeRoot, 'packages');
  if (!fs.existsSync(packagesRoot)) return [];
  const result: string[] = [];
  const walk = (directory: string, relativeDirectory: string) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const absolutePath = path.join(directory, entry.name);
      const relativePath = path.join(relativeDirectory, entry.name);
      if (entry.isDirectory()) {
        walk(absolutePath, relativePath);
        continue;
      }
      if (!entry.isFile() || !/\.(?:png|jpe?g|webp|mp3)$/i.test(entry.name)) continue;
      const normalized = relativePath.split(path.sep).join('/');
      if (RUNTIME_MEDIA_ROOTS.some((root) => normalized.includes(`/${root}/`))) {
        result.push(normalized);
      }
    }
  };
  for (const entry of fs.readdirSync(packagesRoot, { withFileTypes: true })) {
    if (entry.isDirectory()) walk(path.join(packagesRoot, entry.name), `packages/${entry.name}`);
  }
  return result.sort();
}

const runtimeMediaAssetPaths = collectRuntimeMediaAssetPaths();

type CatalogCard = {
  name?: unknown;
  art?: { src?: unknown };
};

function readCatalogCardArt(): Map<string, Buffer> {
  if (!fs.existsSync(cardCatalogPath)) return new Map();
  try {
    const source = JSON.parse(fs.readFileSync(cardCatalogPath, 'utf8')) as { cards?: unknown };
    const cards = Array.isArray(source.cards) ? source.cards : [];
    const assets = new Map<string, Buffer>();
    for (const raw of cards) {
      if (!raw || typeof raw !== 'object') continue;
      const card = raw as CatalogCard;
      if (typeof card.name !== 'string' || !/^[A-Za-z0-9_-]+$/.test(card.name)) continue;
      const localFile = path.join(localCatalogArtRoot, `${card.name}.png`);
      if (fs.existsSync(localFile) && fs.statSync(localFile).isFile()) {
        assets.set(card.name, fs.readFileSync(localFile));
        continue;
      }
      const src = card.art?.src;
      if (typeof src !== 'string' || !src.startsWith('data:image/png;base64,')) continue;
      try {
        assets.set(card.name, Buffer.from(src.slice('data:image/png;base64,'.length), 'base64'));
      } catch {
        // A malformed catalogue entry remains a neutral card fallback.
      }
    }
    return assets;
  } catch {
    return new Map();
  }
}

const servePackagesPlugin: Plugin = {
  name: 'serve-packages',
  configureServer(server) {
    const catalogArt = readCatalogCardArt();
    server.middlewares.use((req, res, next) => {
      if (req.url && req.url.startsWith('/card-catalog-art/')) {
        const encodedName = req.url.slice('/card-catalog-art/'.length).split('?')[0].replace(/\.png$/i, '');
        let name: string;
        try {
          name = decodeURIComponent(encodedName);
        } catch {
          res.statusCode = 400;
          res.end('Invalid card art path');
          return;
        }
        const source = /^[A-Za-z0-9_-]+$/.test(name) ? catalogArt.get(name) : undefined;
        if (source) {
          res.setHeader('Content-Type', 'image/png');
          res.setHeader('Cache-Control', 'no-cache');
          res.end(source);
          return;
        }
      }
      if (req.url && req.url.startsWith('/packages/')) {
        const encodedPath = req.url.slice(1).split('?')[0];
        let relativePath: string;
        try {
          relativePath = decodeURIComponent(encodedPath);
        } catch {
          res.statusCode = 400;
          res.end('Invalid asset path');
          return;
        }
        const filePath = path.resolve(runtimeRoot, relativePath);
        const relativeToRuntime = path.relative(runtimeRoot, filePath);
        const isInsideRuntime = relativeToRuntime === '' ||
          (!relativeToRuntime.startsWith('..') && !path.isAbsolute(relativeToRuntime));
        const ext = path.extname(filePath).toLowerCase();
        const supported = new Set(['.png', '.jpg', '.jpeg', '.webp', '.mp3']);
        if (isInsideRuntime && supported.has(ext) && fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
          res.setHeader('Content-Type', ext === '.mp3' ? 'audio/mpeg' : ext === '.png' ? 'image/png' : ext === '.webp' ? 'image/webp' : 'image/jpeg');
          res.setHeader('Cache-Control', 'no-cache');
          fs.createReadStream(filePath).pipe(res);
          return;
        }
      }
      next();
    });
  },
  generateBundle() {
    const mediaPaths = [...new Set([...nativeCardAssetPaths, ...runtimeMediaAssetPaths])];
    for (const relativePath of mediaPaths) {
      const filePath = path.resolve(runtimeRoot, relativePath);
      if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
        this.warn(`Native card asset is unavailable and will use the neutral fallback: ${relativePath}`);
        continue;
      }
      this.emitFile({
        type: 'asset',
        fileName: relativePath,
        source: fs.readFileSync(filePath),
      });
    }
    for (const [name, source] of readCatalogCardArt()) {
      this.emitFile({
        type: 'asset',
        fileName: `card-catalog-art/${name}.png`,
        source,
      });
    }
  },
};

/**
 * The real-Lua browser fixture normally receives these bytes through
 * Playwright route interception. Serve the same deterministic payload from
 * the local dev server so the fixture is playable directly in Chrome too.
 */
const serveRealLuaFixturePlugin: Plugin = {
  name: 'serve-real-lua-fixture',
  configureServer(server) {
    let fixture: { zip: Buffer; publicKey: string } | undefined;
    const getFixture = () => {
      if (fixture) return fixture;
      const files = Object.fromEntries(loadUpstreamFiles(upstreamRoot, BASELINE_PACKAGE_NAMES));
      const { publicKey } = generateKeyPairSync('rsa', {
        modulusLength: 1024,
        publicExponent: 0x10001,
        publicKeyEncoding: { type: 'pkcs1', format: 'pem' },
        privateKeyEncoding: { type: 'pkcs1', format: 'pem' },
      });
      fixture = { zip: Buffer.from(zipSync(files, { level: 1 })), publicKey };
      return fixture;
    };

    server.middlewares.use((req, res, next) => {
      const pathname = req.url?.split('?')[0];
      if (pathname === '/__tqs_fixture_lua.zip') {
        const { zip } = getFixture();
        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/zip');
        res.setHeader('Content-Length', String(zip.byteLength));
        res.end(zip);
        return;
      }
      if (pathname === '/__tqs_fixture_key.txt') {
        const { publicKey } = getFixture();
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        res.end(publicKey);
        return;
      }
      next();
    });
  },
};

export default defineConfig({
  plugins: [react(), servePackagesPlugin, serveRealLuaFixturePlugin],
  server: {
    proxy: {
      '/gateway': {
        target: 'http://127.0.0.1:8080',
        changeOrigin: true,
        ws: true,
        rewrite: (p) => p.replace(/^\/gateway/, ''),
      },
    },
  },
});
