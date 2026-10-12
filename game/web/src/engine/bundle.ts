import { unzipSync } from 'fflate';

export interface GatewayManifest {
  md5: string;
  packages: string[];
  fileCount: number;
  bundle: string;
  bundleHash: string;
}

export interface LoadedBundle {
  manifest: GatewayManifest;
  files: Map<string, Uint8Array>;
}

const MAX_BUNDLE_BYTES = 12 * 1024 * 1024;
const MAX_UNPACKED_BYTES = 60 * 1024 * 1024;

function assertManifest(raw: unknown): asserts raw is GatewayManifest {
  if (!raw || typeof raw !== 'object') throw new Error('Manifest không hợp lệ');
  const m = raw as Partial<GatewayManifest>;
  if (!/^[a-f\d]{32}$/i.test(m.md5 ?? '')) throw new Error('Gateway chưa có MD5 server hợp lệ');
  if (!/^[a-f\d]{16}$/i.test(m.bundleHash ?? '')) throw new Error('Manifest thiếu bundleHash');
  if (!Array.isArray(m.packages) || !m.packages.every((p) => typeof p === 'string' && /^[\w-]+$/.test(p)) || !m.packages.includes('freekill-core') || !m.packages.includes('hegemony') || !m.packages.includes('utility')) {
    throw new Error('Gateway thiếu package FreeKill/Utility/Hegemony');
  }
  if (!Number.isSafeInteger(m.fileCount) || (m.fileCount ?? 0) < 1 || (m.fileCount ?? 0) > 10000) {
    throw new Error('Số lượng tệp không hợp lệ');
  }
  if (typeof m.bundle !== 'string' || !/^bundle\.zip\?v=[a-f\d]{16}$/i.test(m.bundle) || m.bundle.split('=')[1].toLowerCase() !== m.bundleHash?.toLowerCase()) {
    throw new Error('Đường dẫn bundle không khớp phiên bản');
  }
}

/** Fetch and verify bytes before they ever enter the Lua filesystem. */
export async function loadGatewayBundle(baseUrl: string, signal?: AbortSignal, progress?: (stage: string) => void): Promise<LoadedBundle> {
  const base = baseUrl.replace(/\/$/, '');
  progress?.('Đang nhận manifest…');
  const metaResponse = await fetch(`${base}/manifest.json`, { cache: 'no-store', signal });
  if (!metaResponse.ok) throw new Error(`Manifest HTTP ${metaResponse.status}`);
  const raw: unknown = await metaResponse.json();
  assertManifest(raw);
  const manifest = raw;

  progress?.('Đang tải package Lua…');
  const response = await fetch(`${base}/${manifest.bundle}`, { signal });
  if (!response.ok) throw new Error(`Bundle HTTP ${response.status}`);
  const declaredSize = Number(response.headers.get('content-length') ?? 0);
  if (declaredSize > MAX_BUNDLE_BYTES) throw new Error('Bundle vượt giới hạn tải');
  const bytes = new Uint8Array(await response.arrayBuffer());
  if (bytes.length > MAX_BUNDLE_BYTES) throw new Error('Bundle vượt giới hạn tải');

  progress?.('Đang xác minh checksum…');
  const digest = await crypto.subtle.digest('SHA-1', bytes);
  const hash = Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, '0')).join('').slice(0, 16);
  if (hash.toLowerCase() !== manifest.bundleHash.toLowerCase()) {
    throw new Error('Bundle checksum không khớp manifest; đã chặn đăng nhập');
  }

  progress?.('Đang giải nén và kiểm tra các tệp…');
  let declaredTotal = 0;
  const unzipped = unzipSync(bytes, { filter: (file) => {
    declaredTotal += file.originalSize;
    if (file.originalSize > MAX_UNPACKED_BYTES || declaredTotal > MAX_UNPACKED_BYTES) {
      throw new Error('Bundle giải nén vượt giới hạn');
    }
    return true;
  } });
  const files = new Map<string, Uint8Array>();
  let total = 0;
  for (const [name, data] of Object.entries(unzipped)) {
    if (!/^packages\/[\w-]+\/(?:[\w.-]+\/)*[\w.-]+\.(?:lua|json|md)$/i.test(name) || name.includes('..')) {
      throw new Error(`Đường dẫn package không an toàn: ${name}`);
    }
    const pkg = name.split('/')[1];
    if (!manifest.packages.includes(pkg)) throw new Error(`Package không có trong manifest: ${pkg}`);
    total += data.length;
    if (total > MAX_UNPACKED_BYTES) throw new Error('Dung lượng package giải nén quá lớn');
    files.set(name, data);
  }
  if (files.size !== manifest.fileCount) throw new Error('Số tệp package không khớp manifest');
  if (!files.has('packages/hegemony/init.lua') || !files.has('packages/utility/init.lua')) {
    throw new Error('Thiếu Lua entrypoint của Hegemony hoặc Utility');
  }
  return { manifest, files };
}
