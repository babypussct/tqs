/**
 * Cloudinary URL Optimizer
 * ========================
 * Chèn transformation params vào Cloudinary URL để tối ưu bandwidth & chất lượng.
 * - File gốc trên Cloudinary KHÔNG bị thay đổi.
 * - URL trong Firestore KHÔNG bị thay đổi.
 * - Áp dụng được cho cả ảnh cũ lẫn mới.
 */

export type CloudinaryQuality =
  | 'auto'
  | 'auto:best'
  | 'auto:good'
  | 'auto:eco'
  | 'auto:low';

export interface CloudinaryOptions {
  /** Width tối đa (px). Ảnh nhỏ hơn width này không bị phóng to (c_limit). */
  width?: number;
  /** Quality preset. Default: 'auto'. Dùng 'auto:low' cho thumbnail nhỏ. */
  quality?: CloudinaryQuality;
  /** Thêm blur placeholder siêu nhỏ (w_30, e_blur:300) cho LQIP. */
  blur?: boolean;
  /** Độ mờ blur (0-2000). Default: 300. Chỉ dùng khi blur=true. */
  blurStrength?: number;
  /** Thêm fl_progressive cho JPEG (hiện từ mờ → rõ). Default: true. */
  progressive?: boolean;
  /** DPR (Device Pixel Ratio). Default: undefined (dùng dpr_auto). */
  dpr?: 1 | 2 | 3;
}

const CLOUDINARY_DOMAIN = 'res.cloudinary.com';
const UPLOAD_SEGMENT = '/image/upload/';
const VIDEO_UPLOAD_SEGMENT = '/video/upload/';

/**
 * Kiểm tra URL có phải Cloudinary không.
 */
export function isCloudinaryUrl(url: string): boolean {
  try {
    return url.includes(CLOUDINARY_DOMAIN);
  } catch {
    return false;
  }
}

/**
 * Chèn Cloudinary transformation vào URL.
 *
 * @example
 * cloudinaryUrl('https://res.cloudinary.com/abc/image/upload/v123/photo.jpg', { width: 400 })
 * // → 'https://res.cloudinary.com/abc/image/upload/c_limit,dpr_auto,f_auto,fl_progressive,q_auto,w_400/v123/photo.jpg'
 */
export function cloudinaryUrl(
  url: string | null | undefined,
  options: CloudinaryOptions = {}
): string {
  if (!url) return '';
  if (!isCloudinaryUrl(url)) return url; // Non-Cloudinary → giữ nguyên

  // Xác định segment upload (image vs video)
  const isVideo = url.includes(VIDEO_UPLOAD_SEGMENT);
  const segment = isVideo ? VIDEO_UPLOAD_SEGMENT : UPLOAD_SEGMENT;

  const segmentIdx = url.indexOf(segment);
  if (segmentIdx === -1) return url; // Không tìm thấy segment → giữ nguyên

  // Kiểm tra đã có transform chưa (tránh double-transform)
  const afterSegment = url.slice(segmentIdx + segment.length);
  if (
    afterSegment.startsWith('f_auto') ||
    afterSegment.startsWith('q_auto') ||
    afterSegment.startsWith('w_') ||
    afterSegment.startsWith('e_blur')
  ) {
    return url; // Đã có transform → giữ nguyên
  }

  const {
    width,
    quality = 'auto',
    blur = false,
    blurStrength = 300,
    progressive = true,
    dpr,
  } = options;

  if (blur) {
    // LQIP placeholder: siêu nhỏ + blur
    const parts = ['e_blur:' + blurStrength, 'f_auto', 'q_1', 'w_30'];
    const transform = parts.join(',');
    return url.slice(0, segmentIdx + segment.length) + transform + '/' + afterSegment;
  }

  // Build transformation string
  const parts: string[] = ['c_limit'];

  if (dpr) {
    parts.push('dpr_' + dpr + '.0');
  } else {
    parts.push('dpr_auto');
  }

  // f_auto không áp dụng cho video (Cloudinary tự xử lý)
  if (!isVideo) {
    parts.push('f_auto');
  }

  // fl_progressive chỉ cho ảnh JPEG
  if (!isVideo && progressive) {
    parts.push('fl_progressive');
  }

  parts.push('q_' + quality);

  if (width) {
    parts.push('w_' + width);
  }

  const transform = parts.join(',');
  return url.slice(0, segmentIdx + segment.length) + transform + '/' + afterSegment;
}

/**
 * Tạo LQIP (Low Quality Image Placeholder) URL — ảnh mờ siêu nhỏ ~1KB.
 * Dùng để hiện placeholder trong lúc chờ ảnh thật load.
 */
export function cloudinaryLqip(url: string | null | undefined): string {
  return cloudinaryUrl(url, { blur: true, blurStrength: 300 });
}

/**
 * Tạo srcSet responsive cho ảnh Cloudinary (1x và 2x).
 * @example
 * cloudinarySrcSet(url, 400)
 * // → 'https://...w_400... 400w, https://...w_800... 800w'
 */
export function cloudinarySrcSet(
  url: string | null | undefined,
  width: number,
  quality: CloudinaryQuality = 'auto'
): string {
  if (!url || !isCloudinaryUrl(url)) return '';
  const w1x = cloudinaryUrl(url, { width, quality, dpr: 1 });
  const w2x = cloudinaryUrl(url, { width: width * 2, quality, dpr: 2 });
  return `${w1x} 1x, ${w2x} 2x`;
}
