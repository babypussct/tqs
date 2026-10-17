import { useEffect, useState, useRef } from 'react';

export interface Point {
  x: number;
  y: number;
}

export interface TargetArrow {
  id: string;
  from: Point;
  to: Point;
  color?: string;
}

export function calculateBezierCurve(from: Point, to: Point, arcFactor = 0.25): { path: string; mid: Point } {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const dist = Math.hypot(dx, dy);

  // Vector vuông góc với đường nối
  const nx = -dy / (dist || 1);
  const ny = dx / (dist || 1);

  // Điểm uốn cong ở giữa
  const midX = (from.x + to.x) / 2 + nx * (dist * arcFactor);
  const midY = (from.y + to.y) / 2 + ny * (dist * arcFactor);

  return {
    path: `M ${from.x.toFixed(1)} ${from.y.toFixed(1)} Q ${midX.toFixed(1)} ${midY.toFixed(1)} ${to.x.toFixed(1)} ${to.y.toFixed(1)}`,
    mid: { x: midX, y: midY },
  };
}

export interface TargetingOverlayProps {
  boardContainerRef: React.RefObject<HTMLElement | null>;
  selectedTargetPlayerIds: number[];
  sourcePlayerId?: number | null;
  active?: boolean;
}

export default function TargetingOverlay({
  boardContainerRef,
  selectedTargetPlayerIds,
  sourcePlayerId,
  active = true,
}: TargetingOverlayProps) {
  const [arrows, setArrows] = useState<TargetArrow[]>([]);
  const animFrameRef = useRef<number | null>(null);

  useEffect(() => {
    if (!active || selectedTargetPlayerIds.length === 0) {
      setArrows([]);
      return;
    }

    const updateCoordinates = () => {
      const container = boardContainerRef.current;
      if (!container) return;
      const containerRect = container.getBoundingClientRect();

      // Tìm vị trí nguồn (Source: lá bài đang chọn hoặc ô đại diện bản thân)
      let sourcePoint: Point | null = null;
      const selectedCardEl = typeof document !== 'undefined'
        ? document.querySelector('.sg-card-button.selected, .sg-hand-fan .selected')
        : null;
      const localSeatEl = typeof document !== 'undefined'
        ? document.querySelector('.board-local-seat')
        : null;

      const srcElement = selectedCardEl || localSeatEl;
      if (srcElement) {
        const rect = srcElement.getBoundingClientRect();
        sourcePoint = {
          x: rect.left + rect.width / 2 - containerRect.left,
          y: rect.top + rect.height / 2 - containerRect.top,
        };
      }

      if (!sourcePoint) {
        setArrows([]);
        return;
      }

      // Tìm vị trí đích (Target: avatar của từng đối thủ được chọn)
      const newArrows: TargetArrow[] = [];
      for (const targetId of selectedTargetPlayerIds) {
        const targetEl = typeof document !== 'undefined'
          ? (document.querySelector(`[data-player-id="${targetId}"]`) ||
             document.querySelector(`.board-opponents [data-seat-id="${targetId}"]`))
          : null;
        if (targetEl) {
          const rect = targetEl.getBoundingClientRect();
          newArrows.push({
            id: `target-${targetId}`,
            from: sourcePoint,
            to: {
              x: rect.left + rect.width / 2 - containerRect.left,
              y: rect.top + rect.height / 2 - containerRect.top,
            },
            color: '#ff4444',
          });
        }
      }

      setArrows(newArrows);
    };

    updateCoordinates();

    const handleResize = () => {
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
      animFrameRef.current = requestAnimationFrame(updateCoordinates);
    };

    window.addEventListener('resize', handleResize);
    window.addEventListener('scroll', handleResize, true);

    return () => {
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('scroll', handleResize, true);
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
    };
  }, [active, selectedTargetPlayerIds, sourcePlayerId, boardContainerRef]);

  if (!active || arrows.length === 0) return null;

  return (
    <svg
      className="sg-targeting-overlay"
      aria-hidden="true"
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        pointerEvents: 'none',
        zIndex: 85,
        overflow: 'visible',
      }}
    >
      <defs>
        {/* Glow effect filter */}
        <filter id="vfx-glow-red" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="3" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>

        {/* Mũi tên nhọn dạ quang */}
        <marker
          id="arrowhead-red"
          markerWidth="10"
          markerHeight="8"
          refX="7"
          refY="4"
          orient="auto"
        >
          <polygon points="0 0, 10 4, 0 8, 2 4" fill="#ff3333" />
        </marker>
      </defs>

      {arrows.map((arrow) => {
        const { path, mid } = calculateBezierCurve(arrow.from, arrow.to);
        return (
          <g key={arrow.id} className="vfx-targeting-group">
            {/* Đường nền mờ phát sáng */}
            <path
              d={path}
              fill="none"
              stroke="#ff1111"
              strokeWidth="6"
              strokeOpacity="0.4"
              strokeLinecap="round"
              filter="url(#vfx-glow-red)"
            />
            {/* Đường chính có animation nét đứt chuyển động */}
            <path
              d={path}
              fill="none"
              stroke="#ffe066"
              strokeWidth="2.5"
              strokeDasharray="8 6"
              className="vfx-target-line-dash"
              markerEnd="url(#arrowhead-red)"
            />
            {/* Điểm phát sáng ở giữa đường cong */}
            <circle
              cx={mid.x}
              cy={mid.y}
              r="3"
              fill="#ffffff"
              filter="url(#vfx-glow-red)"
            />
          </g>
        );
      })}
    </svg>
  );
}

export const TargetingArrowOverlay = TargetingOverlay;
