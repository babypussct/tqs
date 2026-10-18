import { useEffect, useState } from 'react';
import type { ActiveCardTargetIndicator } from './store/cardVfxState';

/**
 * Authentic FreeKill IndicatorLine (IndicatorLine.qml) & Target Indicator.
 * Direct 1:1 reproduction of upstream FreeKill RoomBase.qml doIndicate() and IndicatorLine.qml:
 * - Straight line from source player avatar center to target player avatar center.
 * - FreeKill canonical color: #96943D (golden-olive).
 * - Outer beam: width 6px, gradient from transparent to rgba(200, 200, 200, 0.12).
 * - Inner beam: width 3px, gradient from transparent to Qt.lighter(#96943D) (#e5e382).
 * - Duration: 700ms (200ms OutCubic extend, 200ms pause, 300ms InQuart fade-out).
 */

export interface Point {
  x: number;
  y: number;
}

export interface FreeKillIndicatorBeam {
  id: string;
  start: Point;
  end: Point;
  length: number;
  gradientId: string;
  angle: number;
}

/**
 * Geometric helper for smooth curve calculation (preserved for compatibility).
 */
export function calculateBezierCurve(from: Point, to: Point, arcFactor = 0.22): { path: string; mid: Point } {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const dist = Math.hypot(dx, dy);

  const nx = -dy / (dist || 1);
  const ny = dx / (dist || 1);

  const midX = (from.x + to.x) / 2 + nx * (dist * arcFactor);
  const midY = (from.y + to.y) / 2 + ny * (dist * arcFactor);

  return {
    path: `M ${from.x.toFixed(1)} ${from.y.toFixed(1)} Q ${midX.toFixed(1)} ${midY.toFixed(1)} ${to.x.toFixed(1)} ${to.y.toFixed(1)}`,
    mid: { x: midX, y: midY },
  };
}

export interface TargetingOverlayProps {
  boardContainerRef: React.RefObject<HTMLElement | null>;
  activeIndicators?: ActiveCardTargetIndicator[];
}

/** Only native Animate/Indicate produces resolving beams; Photo selection stays in the avatar UI. */
export default function TargetingOverlay({ boardContainerRef, activeIndicators = [] }: TargetingOverlayProps) {
  const [beams, setBeams] = useState<FreeKillIndicatorBeam[]>([]);

  useEffect(() => {
    if (!activeIndicators.length) { setBeams([]); return; }
    const update = () => {
      const container = boardContainerRef.current;
      const board = container?.closest('.sg-game-board');
      if (!container || !board) return;
      const rect = container.getBoundingClientRect();
      const center = (id: number): Point | null => {
        // The local seat can be either the source or a chained target.
        const photo = board.querySelector<HTMLElement>(`.sg-photo-panel[data-player-id="${id}"]`);
        if (!photo) return null;
        const r = photo.getBoundingClientRect();
        return { x: r.left + r.width / 2 - rect.left, y: r.top + r.height / 2 - rect.top };
      };
      const next: FreeKillIndicatorBeam[] = [];
      for (const indicator of activeIndicators) {
        const from = center(indicator.fromPlayerId);
        if (!from) continue;
        for (const playerId of indicator.toPlayerIds) {
          if (playerId === indicator.fromPlayerId) continue;
          const to = center(playerId);
          if (!to) continue;
          const dx = to.x - from.x, dy = to.y - from.y;
          const length = Math.hypot(dx, dy);
          if (length < 1) continue;
          next.push({ id: `${indicator.id}-${playerId}`, start: from, end: to, length,
            angle: Math.atan2(-dx, dy) * 180 / Math.PI,
            gradientId: `fk-grad-${indicator.id}-${playerId}` });
        }
      }
      setBeams(next);
    };
    update();
    let frame: number | null = null;
    const onLayout = () => {
      if (frame !== null) cancelAnimationFrame(frame);
      frame = requestAnimationFrame(update);
    };
    window.addEventListener('resize', onLayout);
    window.addEventListener('scroll', onLayout, true);
    return () => {
      window.removeEventListener('resize', onLayout);
      window.removeEventListener('scroll', onLayout, true);
      if (frame !== null) cancelAnimationFrame(frame);
    };
  }, [activeIndicators, boardContainerRef]);

  if (!beams.length) return null;
  return <svg className="sg-targeting-overlay fk-indicator-overlay" aria-hidden="true"
    style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none',
      zIndex: 88, overflow: 'visible' }}>
    <defs>
      {beams.map((beam) => <linearGradient key={`${beam.gradientId}-outer`}
        id={`${beam.gradientId}-outer`} x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#ffffff" stopOpacity="0" />
        <stop offset="100%" stopColor="#c8c8c8" stopOpacity="0.12" />
      </linearGradient>)}
      {beams.map((beam) => <linearGradient key={beam.gradientId}
        id={beam.gradientId} x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stopColor="#ffffff" stopOpacity="0" />
        <stop offset="100%" stopColor="#e5e382" stopOpacity="1" />
      </linearGradient>)}
    </defs>
    {beams.map((beam) => <g key={beam.id} className="fk-indicator-line-beam"
      transform={`translate(${beam.start.x} ${beam.start.y}) rotate(${beam.angle})`}>
      {/* Growing the rectangles scales the gradient too, like IndicatorLine.qml's ratio. */}
      <g className="fk-indicator-grow">
        <rect x={-3} y={0} width={6} height={beam.length} fill={`url(#${beam.gradientId}-outer)`} />
        <rect x={-1.5} y={0} width={3} height={beam.length} fill={`url(#${beam.gradientId})`} />
      </g>
    </g>)}
  </svg>;
}

export const TargetingArrowOverlay = TargetingOverlay;
