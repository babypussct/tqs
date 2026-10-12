import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { packageRelease } from './package-release.mjs';
import { verifyRelease } from './verify-release.mjs';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

function usage() {
  return [
    'Usage: node deploy/mobile/release-checkpoint.mjs',
    '  --runtime /absolute/pinned/runtime',
    '  --output /absolute/new/release-directory',
    '  --evidence /absolute/evidence.json',
    '  [--created-at 2026-10-13T00:00:00.000Z]',
    '  [--require-clean]',
  ].join('\n');
}

function parseArgs(argv) {
  const result = { requireClean: false };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--require-clean') {
      result.requireClean = true;
      continue;
    }
    const optionNames = {
      '--runtime': 'runtime',
      '--output': 'output',
      '--evidence': 'evidence',
      '--created-at': 'createdAt',
    };
    if (!Object.prototype.hasOwnProperty.call(optionNames, arg)) {
      throw new Error(`${usage()}\nUnknown argument: ${arg}`);
    }
    const value = argv[index + 1];
    if (!value || value.startsWith('--')) throw new Error(`${usage()}\nMissing value for ${arg}`);
    result[optionNames[arg]] = value;
    index += 1;
  }
  for (const key of ['runtime', 'output', 'evidence']) {
    if (!result[key]) throw new Error(usage());
  }
  return result;
}

function git(...args) {
  return execFileSync('git', args, {
    cwd: repo,
    encoding: 'utf8',
    maxBuffer: 8 * 1024 * 1024,
    stdio: ['ignore', 'pipe', 'pipe'],
  }).trimEnd();
}

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function countFiles(root) {
  let count = 0;
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const absolute = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(absolute);
      else if (entry.isFile()) count += 1;
    }
  };
  walk(root);
  return count;
}

function readGitState() {
  const status = git('status', '--short', '--untracked-files=all');
  return {
    branch: git('branch', '--show-current') || '(detached HEAD)',
    commit: git('rev-parse', 'HEAD'),
    dirty: status.length > 0,
    changedFileCount: status ? status.split('\n').filter(Boolean).length : 0,
  };
}

export function createReleaseEvidence({
  releaseRoot,
  manifest,
  gitState,
  generatedAt,
  diffCheck,
}) {
  const manifestPath = path.join(releaseRoot, 'RELEASE.json');
  const holdReasons = [];
  if (gitState.dirty) {
    holdReasons.push('source checkout is dirty; create a reviewed commit or immutable source snapshot before publishing');
  }
  if (diffCheck !== 'PASS') holdReasons.push('git diff --check did not pass');

  const report = {
    schemaVersion: 1,
    checkpoint: 'CP24-safe-release',
    generatedAt,
    status: holdReasons.length ? 'HOLD' : 'READY_FOR_PUBLISH_REVIEW',
    publishEligible: holdReasons.length === 0,
    git: gitState,
    artifact: {
      releaseRoot,
      manifestSha256: sha256(manifestPath),
      releaseFileCount: Object.keys(manifest.files).length,
      runtimeMD5: manifest.runtimeMD5,
      packages: manifest.packages,
      runtimeFileCount: manifest.runtimeFileCount,
      webFileCount: manifest.webFileCount,
      gatewayFileCount: manifest.gatewayFileCount,
      bundleEntrySha256: manifest.files['dist/index.html'] ?? null,
      createdAt: manifest.createdAt,
    },
    gates: {
      sourceProvenance: gitState.dirty ? 'HOLD' : 'PASS',
      gitDiffCheck: diffCheck,
      releasePackageAndManifest: 'PASS',
      requiredRuntimePackages: 'PASS',
      sensitiveFilesAndSymlinks: 'PASS',
      liveGameplayAndNativeRules: 'PENDING',
      coldStartQuotaRollbackSla: 'PENDING',
      physicalDeviceAndNetwork: 'DEFERRED',
      officialRelease: 'PENDING',
    },
    holdReasons,
    safety: {
      deployed: false,
      changesProductionBundle: false,
      credentialsIncluded: false,
      note: 'This report is a local release-candidate checkpoint. It does not authorize deployment or official release.',
    },
  };
  return report;
}

export function runReleaseCheckpoint(options) {
  const runtime = path.resolve(options.runtime);
  const output = path.resolve(options.output);
  const evidence = path.resolve(options.evidence);
  const gitState = readGitState();
  if (options.requireClean && gitState.dirty) {
    throw new Error('Refusing release checkpoint: source checkout is dirty; use a reviewed clean snapshot.');
  }

  execFileSync('git', ['diff', '--check'], {
    cwd: repo,
    stdio: 'pipe',
  });

  const createdAt = options.createdAt ?? new Date().toISOString();
  const packaged = packageRelease(runtime, output, { createdAt });
  const verified = verifyRelease(output);
  const report = createReleaseEvidence({
    releaseRoot: verified.root,
    manifest: verified.manifest,
    gitState,
    generatedAt: new Date().toISOString(),
    diffCheck: 'PASS',
  });
  fs.mkdirSync(path.dirname(evidence), { recursive: true });
  fs.writeFileSync(evidence, `${JSON.stringify({
    ...report,
    artifact: {
      ...report.artifact,
      releaseFileCount: verified.fileCount,
      releaseDirectoryFileCount: countFiles(verified.root),
    },
  }, null, 2)}\n`);
  return { ...report, output: packaged.output, evidence };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const options = parseArgs(process.argv.slice(2));
    const result = runReleaseCheckpoint(options);
    console.log(`Release checkpoint ${result.status}: ${result.output}`);
    console.log(`Evidence: ${result.evidence}`);
    console.log(`Publish eligible: ${result.publishEligible ? 'yes' : 'no'}`);
  } catch (error) {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  }
}
