import { fileURLToPath } from 'node:url';
import { realpathSync, existsSync } from 'node:fs';
import { changedPaths, classifyPaths, git, root } from './change-scopes.mjs';

// Dashboard bootstrap works even before this file reaches the linked Git branch.
// Once present, the versioned classifier takes over. The fallback only skips
// known game/docs trees; every unknown path or unavailable baseline builds.
export const bootstrapIgnoreCommand = `[ ! -f build/vercel-ignore.mjs ] || exec node build/vercel-ignore.mjs; git diff --no-renames --quiet "$VERCEL_GIT_PREVIOUS_SHA" HEAD -- . ':!game' ':!runtime' ':!gateway' ':!deploy' ':!docs' ':!dist' ':!scratch' ':!spikes' ':!README.md' ':!AGENTS.md'`;

// Vercel uses the inverse of a normal test: 0 = skip, 1 = continue building.
export function shopBuildDecision(env, cwd = root) {
  try {
    const head = git(['rev-parse', 'HEAD'], cwd).trim();
    if (!env.VERCEL_GIT_COMMIT_SHA || head !== env.VERCEL_GIT_COMMIT_SHA) throw new Error('No matching Git deployment');
    const scopes = classifyPaths(changedPaths(env.VERCEL_GIT_PREVIOUS_SHA, head, { cwd }));
    return { build: scopes.shop, reason: scopes.shop ? 'Shop/shared paths changed' : 'Only TQSVN/docs/legacy paths changed' };
  } catch {
    // First deploy, shallow history, local/CLI deploy or missing system envs: build.
    return { build: true, reason: 'No reliable previous deployment baseline; continue building' };
  }
}

if (process.argv[1] && existsSync(process.argv[1]) && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const decision = shopBuildDecision(process.env);
  console.log(`${decision.build ? 'BUILD' : 'SKIP'} TQSShop: ${decision.reason}`);
  process.exitCode = decision.build ? 1 : 0;
}
