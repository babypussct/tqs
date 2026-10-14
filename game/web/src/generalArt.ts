/**
 * Browser-side equivalent of FreeKill's SkinBank.getGeneralPicture().
 *
 * The native client resolves a general through its owning extension and then
 * asks for an exact `<general>.jpg`. The web release intentionally ships only
 * the small public fixture pack; the runtime package snapshot contains Lua/
 * JSON/QML/JS, but not the native image tree. Do not probe speculative
 * `/assets`, `/packages`, or `/photo-assets` URLs for every native variant:
 * those requests only produce avoidable 404s before the safe CSS sigil is
 * rendered. No fuzzy variant aliasing is performed.
 */

import generalList from './generalArtList.json';

export interface GeneralArtRef {
  name?: string | null;
  extension?: string | null;
}

const SAFE_ASSET_PART = /^[A-Za-z0-9_-]+$/;
const LOCAL_GENERAL_NAMES = new Set<string>(generalList);

function safePart(value: string | null | undefined): string | null {
  return value && SAFE_ASSET_PART.test(value) ? value : null;
}

function withExtensions(base: string): string[] {
  return ['jpg', 'png', 'webp'].map((extension) => `${base}.${extension}`);
}

/** Return ordered exact candidates; duplicate URLs are removed. */
export function generalArtCandidates({ name }: GeneralArtRef): string[] {
  const safeName = safePart(name);
  if (!safeName) return [];
  const candidates: string[] = [];
  const add = (value: string) => { if (!candidates.includes(value)) candidates.push(value); };

  // 1. Exact name match if available locally
  if (LOCAL_GENERAL_NAMES.has(safeName)) {
    for (const file of withExtensions(`/photo-assets/generals/${safeName}`)) add(file);
  }

  // 2. Base name match (e.g. m_heg__dianwei -> dianwei, ld__bianfuren -> bianfuren)
  const baseName = safeName.split('__').at(-1);
  if (baseName && baseName !== safeName && LOCAL_GENERAL_NAMES.has(baseName)) {
    for (const file of withExtensions(`/photo-assets/generals/${baseName}`)) add(file);
  }

  return candidates;
}
