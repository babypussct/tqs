/**
 * Browser-side equivalent of FreeKill's SkinBank.getGeneralPicture().
 *
 * The native client resolves a general through its owning extension and then
 * asks for an exact `<general>.jpg`.  The web client cannot inspect the native
 * filesystem, so it tries the gateway asset route first, the Vite runtime
 * route during local development, and finally the small public fixture pack.
 * No fuzzy variant aliasing is performed: a missing exact portrait falls back
 * to the CSS portrait back in PlayerPhotoPanel.
 */

export interface GeneralArtRef {
  name?: string | null;
  extension?: string | null;
}

const SAFE_ASSET_PART = /^[A-Za-z0-9_-]+$/;
const LOCAL_GENERAL_NAMES = new Set([
  'caocao', 'diaochan', 'godlvbu', 'guanyu', 'zhaoyun', 'zhouyu',
]);

function safePart(value: string | null | undefined): string | null {
  return value && SAFE_ASSET_PART.test(value) ? value : null;
}

function withExtensions(base: string): string[] {
  return ['jpg', 'png', 'webp'].map((extension) => `${base}.${extension}`);
}

/** Return ordered exact candidates; duplicate URLs are removed. */
export function generalArtCandidates({ name, extension }: GeneralArtRef): string[] {
  const safeName = safePart(name);
  if (!safeName) return [];
  const safeExtension = safePart(extension);
  const candidates: string[] = [];
  const add = (value: string) => { if (!candidates.includes(value)) candidates.push(value); };

  if (safeExtension) {
    for (const file of withExtensions(`/assets/${safeExtension}/image/generals/${safeName}`)) add(file);
    // Vite's local development middleware exposes runtime media at /packages.
    for (const file of withExtensions(`/packages/${safeExtension}/image/generals/${safeName}`)) add(file);
  }

  for (const file of withExtensions(`/photo-assets/generals/${safeName}`)) add(file);

  // The fixture pack intentionally contains only a few exact base-name
  // portraits.  A base-name fallback is allowed only when that exact local
  // file is known to exist; it never maps one native variant to another.
  const baseName = safeName.split('__').at(-1);
  if (baseName && LOCAL_GENERAL_NAMES.has(baseName) && baseName !== safeName) {
    for (const file of withExtensions(`/photo-assets/generals/${baseName}`)) add(file);
  }
  return candidates;
}
