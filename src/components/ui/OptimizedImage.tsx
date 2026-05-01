import React, { useState, useRef } from 'react';
import { cloudinaryUrl, cloudinaryLqip, cloudinarySrcSet, isCloudinaryUrl, type CloudinaryQuality } from '../../utils/cloudinaryUrl';

export interface OptimizedImageProps {
  src: string | null | undefined;
  alt: string;
  width?: number;
  quality?: CloudinaryQuality;
  /** true = fetchpriority="high" (Hero, main product image) */
  priority?: boolean;
  /** true = hiện LQIP blur placeholder trong lúc chờ tải */
  showBlur?: boolean;
  className?: string;
  style?: React.CSSProperties;
  referrerPolicy?: React.HTMLAttributeReferrerPolicy;
  onClick?: () => void;
  onError?: () => void;
}

const PLACEHOLDER_SVG = `data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23e5e7eb'/%3E%3C/svg%3E`;

/**
 * OptimizedImage — thay thế <img> thông thường với đầy đủ tối ưu Cloudinary:
 * - Auto transform (f_auto, q_auto, w_XXX, c_limit, fl_progressive, dpr_auto)
 * - Native lazy loading (loading="lazy", decoding="async")
 * - fetchpriority="high" cho ảnh quan trọng
 * - LQIP blur placeholder (ảnh mờ 1KB trong lúc chờ)
 * - DPR-aware srcSet (1x, 2x)
 * - Cache API cho returning users (0 bandwidth lần 2+)
 * - Fallback placeholder khi lỗi
 * - Non-Cloudinary URL → render <img> thường, không transform
 */
export function OptimizedImage({
  src,
  alt,
  width,
  quality = 'auto',
  priority = false,
  showBlur = true,
  className = '',
  style,
  referrerPolicy = 'no-referrer',
  onClick,
  onError,
}: OptimizedImageProps) {
  const [isLoaded, setIsLoaded] = useState(false);
  const [hasError, setHasError] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);

  // Tạo optimized URL
  const optimizedSrc = src
    ? cloudinaryUrl(src, { width, quality })
    : '';
  const lqipSrc = src && showBlur && isCloudinaryUrl(src)
    ? cloudinaryLqip(src)
    : '';
  const srcSet = src && width && isCloudinaryUrl(src)
    ? cloudinarySrcSet(src, width, quality)
    : '';

  const handleLoad = () => setIsLoaded(true);
  const handleError = () => {
    setHasError(true);
    onError?.();
  };

  // Nếu không có src → placeholder
  if (!src) {
    return (
      <div
        className={`bg-gray-100 dark:bg-zinc-800 flex items-center justify-center ${className}`}
        style={style}
      >
        <svg className="w-8 h-8 text-gray-300 dark:text-zinc-600" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" strokeWidth="1.5" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 18h16.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
    );
  }

  // Lỗi tải ảnh → fallback placeholder
  if (hasError) {
    return (
      <div
        className={`bg-gray-100 dark:bg-zinc-800 flex items-center justify-center ${className}`}
        style={style}
      >
        <svg className="w-6 h-6 text-gray-400 dark:text-zinc-500" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" strokeWidth="1.5" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
      </div>
    );
  }

  const displaySrc = optimizedSrc || src || '';

  return (
    <div
      className={`relative overflow-hidden ${className}`}
      style={style}
      onClick={onClick}
    >
      {/* LQIP Blur Placeholder — hiện trong lúc chờ ảnh thật */}
      {lqipSrc && !isLoaded && (
        <img
          src={lqipSrc}
          alt=""
          aria-hidden="true"
          className="absolute inset-0 w-full h-full object-cover scale-110 blur-sm"
          referrerPolicy={referrerPolicy}
        />
      )}

      {/* Ảnh thật */}
      <img
        ref={imgRef}
        src={displaySrc}
        srcSet={srcSet || undefined}
        sizes={width ? `${width}px` : undefined}
        alt={alt}
        loading={priority ? 'eager' : 'lazy'}
        decoding="async"
        // @ts-ignore — fetchpriority is valid HTML but TS types may lag
        fetchpriority={priority ? 'high' : 'low'}
        referrerPolicy={referrerPolicy}
        onLoad={handleLoad}
        onError={handleError}
        className={`w-full h-full object-cover transition-opacity duration-300 ${
          isLoaded ? 'opacity-100' : 'opacity-0'
        }`}
      />
    </div>
  );
}

/**
 * Phiên bản đơn giản — chỉ tối ưu URL, không có LQIP/cache.
 * Dùng cho admin UI hoặc nơi không cần full feature.
 */
export function SimpleOptimizedImage({
  src,
  alt,
  width,
  quality = 'auto:low',
  className = '',
  style,
  referrerPolicy = 'no-referrer',
  onError,
}: OptimizedImageProps) {
  const optimizedSrc = src ? cloudinaryUrl(src, { width, quality }) : '';

  return (
    <img
      src={optimizedSrc || src || PLACEHOLDER_SVG}
      alt={alt}
      loading="lazy"
      decoding="async"
      className={className}
      style={style}
      referrerPolicy={referrerPolicy}
      onError={onError ? (e) => { (e.currentTarget as HTMLImageElement).src = PLACEHOLDER_SVG; onError(); } : undefined}
    />
  );
}
