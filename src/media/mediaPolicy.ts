export const MEDIA_CATEGORIES = ['products', 'posts', 'banners'] as const;
export type MediaCategory = (typeof MEDIA_CATEGORIES)[number];

export const MEDIA_CONTENT_TYPES = ['image/jpeg', 'image/png', 'image/webp'] as const;
export type MediaContentType = (typeof MEDIA_CONTENT_TYPES)[number];

export const MAX_MEDIA_BYTES = 5 * 1024 * 1024;
export const MEDIA_CACHE_CONTROL = 'public, max-age=31536000, immutable';

const EXTENSION_BY_CONTENT_TYPE: Record<MediaContentType, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

export interface MediaUploadRequest {
  filename: unknown;
  contentType: unknown;
  size: unknown;
  category: unknown;
}

export interface ValidatedMediaUploadRequest {
  filename: string;
  contentType: MediaContentType;
  size: number;
  category: MediaCategory;
  extension: string;
}

export interface MediaValidationError {
  code:
    | 'INVALID_FILENAME'
    | 'INVALID_CONTENT_TYPE'
    | 'INVALID_FILE_SIZE'
    | 'INVALID_CATEGORY';
  message: string;
}

export type MediaValidationResult =
  | { ok: true; value: ValidatedMediaUploadRequest }
  | { ok: false; error: MediaValidationError };

function failure(code: MediaValidationError['code'], message: string): MediaValidationResult {
  return { ok: false, error: { code, message } };
}

export function validateMediaUploadRequest(input: MediaUploadRequest): MediaValidationResult {
  if (
    typeof input.filename !== 'string' ||
    input.filename.trim().length === 0 ||
    input.filename.trim().length > 255 ||
    /[\\/\0-\x1F\x7F]/.test(input.filename)
  ) {
    return failure('INVALID_FILENAME', 'Tên file không hợp lệ.');
  }

  const contentType = typeof input.contentType === 'string'
    ? input.contentType.trim().toLowerCase()
    : '';
  if (!MEDIA_CONTENT_TYPES.includes(contentType as MediaContentType)) {
    return failure('INVALID_CONTENT_TYPE', 'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP.');
  }

  if (
    typeof input.size !== 'number' ||
    !Number.isInteger(input.size) ||
    input.size <= 0 ||
    input.size > MAX_MEDIA_BYTES
  ) {
    return failure('INVALID_FILE_SIZE', `Dung lượng file phải nằm trong khoảng 1 byte đến ${MAX_MEDIA_BYTES} byte.`);
  }

  if (!MEDIA_CATEGORIES.includes(input.category as MediaCategory)) {
    return failure('INVALID_CATEGORY', 'category không hợp lệ.');
  }

  return {
    ok: true,
    value: {
      filename: input.filename.trim(),
      contentType: contentType as MediaContentType,
      size: input.size,
      category: input.category as MediaCategory,
      extension: EXTENSION_BY_CONTENT_TYPE[contentType as MediaContentType],
    },
  };
}

export function normalizePublicBaseUrl(value: unknown): string | null {
  if (typeof value !== 'string' || value.trim() === '') return null;

  const raw = value.trim();
  const withProtocol = /^https?:\/\//i.test(raw) ? raw : `https://${raw}`;
  try {
    const url = new URL(withProtocol);
    if (url.protocol !== 'https:' && url.protocol !== 'http:') return null;
    return url.toString().replace(/\/+$/, '');
  } catch {
    return null;
  }
}

export interface MediaAuthorityProfile {
  role?: unknown;
  isSuperAdmin?: unknown;
  adminPermissions?: Record<string, unknown> | null;
}

export interface MediaAuthorityClaims {
  super_admin?: unknown;
}

export function hasMediaUploadPermission(
  category: MediaCategory,
  profile: MediaAuthorityProfile,
  claims: MediaAuthorityClaims = {},
): boolean {
  if (claims.super_admin === true || profile.isSuperAdmin === true) return true;
  if (profile.role !== 'admin') return false;

  const permissions = profile.adminPermissions || {};
  switch (category) {
    case 'products':
      return permissions.manageProducts === true;
    case 'banners':
      return permissions.manageHomepage === true || permissions.manageSettings === true;
    case 'posts':
      // Keep post editors least-privileged while allowing legacy admins whose
      // homepage permission also covered editorial media before managePosts existed.
      return permissions.managePosts === true || permissions.manageHomepage === true;
    default:
      return false;
  }
}

export function buildMediaObjectKey(
  category: MediaCategory,
  extension: string,
  now: Date,
  objectId: string,
): string {
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, '0');
  return `uploads/${category}/${year}/${month}/${objectId}${extension}`;
}
