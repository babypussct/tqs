import { CLIENT_VERSION } from './clientVersion';

declare const __APP_BUILD_ID__: string;
declare const __APP_BUILT_AT__: string;
export interface BuildInfo { version: string; buildId: string; swVersion: string; builtAt: string }
export const BUILD: BuildInfo = {
  version: CLIENT_VERSION,
  buildId: typeof __APP_BUILD_ID__ === 'string' && !__APP_BUILD_ID__.startsWith('__TQS_') ? __APP_BUILD_ID__ : 'development',
  swVersion: typeof __APP_BUILD_ID__ === 'string' && !__APP_BUILD_ID__.startsWith('__TQS_') ? __APP_BUILD_ID__ : 'development',
  builtAt: typeof __APP_BUILT_AT__ === 'string' && !__APP_BUILT_AT__.startsWith('__TQS_') ? __APP_BUILT_AT__ : '',
};
export function buildLabel(build: BuildInfo): string {
  const date = new Date(build.builtAt);
  const day = Number.isNaN(date.valueOf()) ? 'local' : new Intl.DateTimeFormat('en-GB', {
    day: '2-digit', month: '2-digit', timeZone: 'Asia/Ho_Chi_Minh',
  }).format(date).replace('/', '');
  return `v${build.version} · ${day}.${build.buildId.slice(0, 4)}`;
}
export function parseBuild(raw: unknown): BuildInfo {
  const b = raw as Partial<BuildInfo> | null;
  if (!b || typeof b.version !== 'string' || !/^\d+\.\d+\.\d+$/.test(b.version) ||
      typeof b.buildId !== 'string' || !/^[a-f\d]{64}$/.test(b.buildId) || b.swVersion !== b.buildId ||
      typeof b.builtAt !== 'string' || Number.isNaN(Date.parse(b.builtAt))) throw new Error('Invalid build metadata');
  return b as BuildInfo;
}
