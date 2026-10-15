import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';

type ReleaseManifest = {
  schemaVersion: number;
  runtimeMD5: string;
  packages: string[];
  files: Record<string, string>;
};

type GatewayManifest = {
  md5?: string;
  packages?: string[];
  bundleHash?: string;
  fileCount?: number;
};

export type CandidateIdentity = {
  releaseManifestSha256: string | null;
  releaseManifestPath: string | null;
  runtimeMD5: string;
  localPackages: string[];
  localServerOnlyPackages: string[];
  distIndexSha256: string;
  deploymentUrl: string | null;
  remoteGatewayManifest?: {
    md5: string;
    packages: string[];
    bundleHash: string | null;
    fileCount: number | null;
  };
  remoteIndexSha256?: string;
};

export type QaPackageIdentity = {
  manifestPath: string;
  manifestSha256: string;
  sourceRevision: string;
  catalogSha256: string;
  packageSha256: string;
};

const SERVER_ONLY_PACKAGES = new Set(['tqs_qa']);

function sha256(bytes: Uint8Array) {
  return createHash('sha256').update(bytes).digest('hex');
}

function md5(bytes: Uint8Array) {
  return createHash('md5').update(bytes).digest('hex');
}

function sortedPackageNames(runtime: string) {
  const root = path.join(runtime, 'packages');
  if (!existsSync(root) || !statSync(root).isDirectory()) throw new Error(`Candidate runtime packages/ is missing: ${root}`);
  return readdirSync(root, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith('.'))
    .map((entry) => entry.name)
    .sort();
}

function sortedServerOnlyPackageNames(runtime: string) {
  const root = path.join(runtime, 'qa_packages');
  if (!existsSync(root) || !statSync(root).isDirectory()) return [];
  return readdirSync(root, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith('.'))
    .map((entry) => entry.name)
    .sort();
}

function assertSortedUnique(values: unknown, label: string): asserts values is string[] {
  if (!Array.isArray(values) || values.some((value) => typeof value !== 'string') ||
      new Set(values).size !== values.length || [...values].sort().join('\0') !== values.join('\0')) {
    throw new Error(`${label} must be a sorted unique string list`);
  }
}

function readReleaseManifest(manifestPath: string): { manifest: ReleaseManifest; hash: string } {
  if (!existsSync(manifestPath) || !statSync(manifestPath).isFile()) throw new Error(`Release manifest is missing: ${manifestPath}`);
  const bytes = readFileSync(manifestPath);
  let manifest: ReleaseManifest;
  try {
    manifest = JSON.parse(bytes.toString('utf8')) as ReleaseManifest;
  } catch {
    throw new Error(`Release manifest is not valid JSON: ${manifestPath}`);
  }
  if (manifest.schemaVersion !== 2 || !/^[a-f0-9]{32}$/i.test(String(manifest.runtimeMD5)))
    throw new Error('Release manifest schema/runtimeMD5 is invalid');
  assertSortedUnique(manifest.packages, 'Release manifest packages');
  if (!manifest.files || typeof manifest.files !== 'object' || Array.isArray(manifest.files))
    throw new Error('Release manifest file inventory is missing');
  if (!/^[a-f0-9]{64}$/i.test(String(manifest.files['dist/index.html'])))
    throw new Error('Release manifest has no valid dist/index.html hash');
  if (manifest.packages.some((name) => SERVER_ONLY_PACKAGES.has(name)))
    throw new Error('Release manifest contains a server-only package');
  return { manifest, hash: sha256(bytes) };
}

export function verifyQaPackageManifest(options: {
  manifestPath: string;
  expectedRevision?: string;
}): QaPackageIdentity {
  const manifestPath = path.resolve(options.manifestPath);
  if (!existsSync(manifestPath) || !statSync(manifestPath).isFile())
    throw new Error(`QA package manifest is missing: ${manifestPath}`);
  const bytes = readFileSync(manifestPath);
  let manifest: Record<string, unknown>;
  try {
    manifest = JSON.parse(bytes.toString('utf8')) as Record<string, unknown>;
  } catch {
    throw new Error('QA package manifest is not valid JSON');
  }
  const sourceRevision = typeof manifest.sourceRevision === 'string' ? manifest.sourceRevision : '';
  const catalogSha256 = typeof manifest.catalogSha256 === 'string' ? manifest.catalogSha256 : '';
  const packageSha256 = typeof manifest.packageSha256 === 'string' ? manifest.packageSha256 : '';
  if (manifest.schemaVersion !== 1 || manifest.package !== 'tqs_qa' || manifest.status !== 'verified' ||
      !/^[a-f0-9]{40}$/i.test(sourceRevision) || !/^[a-f0-9]{64}$/i.test(catalogSha256) ||
      !/^[a-f0-9]{64}$/i.test(packageSha256)) {
    throw new Error('QA package manifest is not a verified tqs_qa manifest');
  }
  if (!options.expectedRevision) throw new Error('TQS_QA_EXPECTED_REVISION is required for native QA runs');
  if (sourceRevision !== options.expectedRevision) throw new Error('QA package revision does not match TQS_QA_EXPECTED_REVISION');
  return {
    manifestPath,
    manifestSha256: sha256(bytes),
    sourceRevision,
    catalogSha256,
    packageSha256,
  };
}

async function fetchBytes(url: string, fetchImpl: typeof fetch) {
  const response = await fetchImpl(url, { cache: 'no-store', redirect: 'error' });
  if (!response.ok) throw new Error(`Candidate identity endpoint ${url} returned HTTP ${response.status}`);
  return response;
}

export async function verifyCandidateIdentity(options: {
  runtime: string;
  dist: string;
  deploymentUrl?: string;
  releaseManifestPath?: string;
  allowUnpinned?: boolean;
  fetchImpl?: typeof fetch;
}): Promise<CandidateIdentity> {
  const runtime = path.resolve(options.runtime);
  const dist = path.resolve(options.dist);
  const flistPath = path.join(runtime, 'flist.txt');
  const indexPath = path.join(dist, 'index.html');
  if (!existsSync(flistPath) || !statSync(flistPath).isFile()) throw new Error(`Candidate runtime flist.txt is missing: ${flistPath}`);
  if (!existsSync(indexPath) || !statSync(indexPath).isFile()) throw new Error(`Candidate web dist/index.html is missing: ${indexPath}`);

  const localPackages = sortedPackageNames(runtime);
  const localServerOnlyPackages = sortedServerOnlyPackageNames(runtime)
    .filter((name) => SERVER_ONLY_PACKAGES.has(name));
  const runtimeMD5 = md5(readFileSync(flistPath));
  const distIndexSha256 = sha256(readFileSync(indexPath));
  const manifestPath = options.releaseManifestPath ? path.resolve(options.releaseManifestPath) : null;
  const allowUnpinned = options.allowUnpinned === true;
  let releaseManifestSha256: string | null = null;

  if (!manifestPath && !allowUnpinned) {
    throw new Error('TQS_RELEASE_MANIFEST is required; set TQS_LIVE_ALLOW_UNPINNED=1 only for an explicitly unpinned diagnostic run');
  }

  if (manifestPath) {
    const { manifest, hash } = readReleaseManifest(manifestPath);
    releaseManifestSha256 = hash;
    if (manifest.runtimeMD5.toLowerCase() !== runtimeMD5) throw new Error('Candidate runtime flist MD5 does not match TQS_RELEASE_MANIFEST');
    if (JSON.stringify(manifest.packages) !== JSON.stringify(localPackages))
      throw new Error('Candidate runtime package inventory does not match TQS_RELEASE_MANIFEST');
    if (String(manifest.files['dist/index.html']).toLowerCase() !== distIndexSha256)
      throw new Error('Candidate dist/index.html does not match TQS_RELEASE_MANIFEST');
  }

  const identity: CandidateIdentity = {
    releaseManifestSha256,
    releaseManifestPath: manifestPath,
    runtimeMD5,
    localPackages,
    localServerOnlyPackages,
    distIndexSha256,
    deploymentUrl: options.deploymentUrl?.replace(/\/$/, '') ?? null,
  };

  if (options.deploymentUrl) {
    const fetchImpl = options.fetchImpl ?? fetch;
    const base = options.deploymentUrl.replace(/\/$/, '');
    const manifestResponse = await fetchBytes(`${base}/gateway/manifest.json`, fetchImpl);
    let remote: GatewayManifest;
    try {
      remote = await manifestResponse.json() as GatewayManifest;
    } catch {
      throw new Error('Hosted gateway manifest is not valid JSON');
    }
    assertSortedUnique(remote.packages, 'Hosted gateway packages');
    if (typeof remote.md5 !== 'string' || !/^[a-f0-9]{32}$/i.test(remote.md5))
      throw new Error('Hosted gateway manifest has no valid md5');
    if (remote.md5.toLowerCase() !== runtimeMD5) throw new Error('Hosted gateway runtime MD5 is stale or from a different release');
    if (JSON.stringify(remote.packages) !== JSON.stringify(localPackages))
      throw new Error('Hosted gateway package inventory is stale or from a different release');
    const remoteIndexResponse = await fetchBytes(`${base}/`, fetchImpl);
    const remoteIndexSha256 = sha256(new Uint8Array(await remoteIndexResponse.arrayBuffer()));
    if (remoteIndexSha256 !== distIndexSha256) throw new Error('Hosted web index is stale or from a different release');
    identity.remoteGatewayManifest = {
      md5: remote.md5.toLowerCase(),
      packages: remote.packages,
      bundleHash: typeof remote.bundleHash === 'string' ? remote.bundleHash : null,
      fileCount: typeof remote.fileCount === 'number' ? remote.fileCount : null,
    };
    identity.remoteIndexSha256 = remoteIndexSha256;
  }

  return identity;
}
