import { existsSync } from 'node:fs';
import path from 'node:path';
import { preview } from 'vite';

const dist = path.resolve(process.argv[2] ?? '');
if (!process.argv[2] || !existsSync(path.join(dist, 'index.html'))) {
  throw new Error('Usage: node scripts/serve-checkpoint.mjs /absolute/checkpoint/dist');
}
// Serve only the frozen build. The existing gateway keeps active games alive.
const server = await preview({
  configFile: false,
  root: path.dirname(dist),
  build: { outDir: dist },
  preview: {
    host: '127.0.0.1', port: Number(process.env.TQS_CHECKPOINT_PORT ?? 5180), strictPort: true,
    allowedHosts: ['.trycloudflare.com'],
    proxy: { '/gateway': { target: 'http://127.0.0.1:8080', ws: true,
      changeOrigin: true, rewrite: (url) => url.replace(/^\/gateway/, '') } },
  },
});
server.printUrls();
