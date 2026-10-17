import React, { useEffect, useState, useRef } from 'react';

export type NativeAnimName =
  | 'slash'
  | 'fire__slash'
  | 'thunder__slash'
  | 'jink'
  | 'peach'
  | 'analeptic'
  | 'damage';

export interface NativeVfxAnimProps {
  animName: NativeAnimName;
  onFinished?: () => void;
  scale?: number;
  intervalMs?: number;
  className?: string;
  style?: React.CSSProperties;
}

export const ANIM_FRAME_COUNTS: Record<NativeAnimName, number> = {
  slash: 24,
  fire__slash: 24,
  thunder__slash: 24,
  jink: 23,
  peach: 17,
  analeptic: 17,
  damage: 6,
};

/**
 * Preload cache for animation frame images to ensure zero-lag rendering.
 */
const preloadedImagesCache = new Map<string, HTMLImageElement[]>();

export function preloadAnimFrames(animName: NativeAnimName, frameCount?: number): Promise<void> {
  if (typeof window === 'undefined') return Promise.resolve();
  const count = frameCount ?? ANIM_FRAME_COUNTS[animName] ?? 24;
  const cacheKey = animName;

  if (preloadedImagesCache.has(cacheKey)) {
    return Promise.resolve();
  }

  const images: HTMLImageElement[] = [];
  const promises: Promise<void>[] = [];

  for (let i = 0; i < count; i++) {
    const img = new Image();
    const p = new Promise<void>((resolve) => {
      img.onload = () => resolve();
      img.onerror = () => resolve(); // resolve anyway to not block
    });
    img.src = `/anim/${animName}/${i}.png`;
    images.push(img);
    promises.push(p);
  }

  preloadedImagesCache.set(cacheKey, images);
  return Promise.all(promises).then(() => undefined);
}

/**
 * Frame-by-frame Pixmap Animation component matching upstream FreeKill's PixmapAnimation.qml.
 * Renders high-fidelity native FreeKill visual effects with automatic frame progression.
 */
export default function NativeVfxAnim({
  animName,
  onFinished,
  scale = 1.0,
  intervalMs = 45,
  className = '',
  style = {},
}: NativeVfxAnimProps) {
  const frameCount = ANIM_FRAME_COUNTS[animName] ?? 24;
  const [currentFrame, setCurrentFrame] = useState(0);
  const [hasError, setHasError] = useState(false);
  const timerRef = useRef<number | null>(null);
  const onFinishedRef = useRef(onFinished);
  onFinishedRef.current = onFinished;

  useEffect(() => {
    // Start animation loop
    let frame = 0;
    const interval = Math.max(25, intervalMs);

    timerRef.current = window.setInterval(() => {
      frame++;
      if (frame >= frameCount) {
        if (timerRef.current !== null) {
          clearInterval(timerRef.current);
          timerRef.current = null;
        }
        if (onFinishedRef.current) {
          onFinishedRef.current();
        }
      } else {
        setCurrentFrame(frame);
      }
    }, interval);

    return () => {
      if (timerRef.current !== null) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [animName, frameCount, intervalMs]);

  if (hasError) {
    return null;
  }

  return (
    <div
      className={`sg-native-vfx-anim anim-${animName} ${className}`}
      style={{
        display: 'inline-block',
        pointerEvents: 'none',
        transform: `scale(${scale})`,
        transformOrigin: 'center center',
        userSelect: 'none',
        ...style,
      }}
    >
      <img
        src={`/anim/${animName}/${currentFrame}.png`}
        alt={`${animName} frame ${currentFrame}`}
        style={{
          display: 'block',
          maxWidth: '220px',
          maxHeight: '220px',
          objectFit: 'contain',
        }}
        onError={() => {
          setHasError(true);
          if (onFinishedRef.current) onFinishedRef.current();
        }}
      />
    </div>
  );
}
