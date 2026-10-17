import { useEffect, useState } from 'react';
import type { FlyingCardEvent, ImpactVfxEvent } from './store/cardVfxState';
import { soundManager } from './engine/webAudioSfx';
import { useDisplayText } from './engine/displayText';
import { CATALOG_CARD_ART_NAMES, catalogCardArtUrl } from './catalogCardArt';
import { getSuitInfo, formatRank, getCardCategory } from './HandCardItem';
import NativeVfxAnim from './NativeVfxAnim';

export interface CardVfxOverlayProps {
  boardContainerRef: React.RefObject<HTMLElement | null>;
  flyingCards: FlyingCardEvent[];
  impacts: ImpactVfxEvent[];
  onFlyingCardDone: (id: string) => void;
  onImpactDone: (id: string) => void;
}

export default function CardVfxOverlay({
  boardContainerRef,
  flyingCards,
  impacts,
  onFlyingCardDone,
  onImpactDone,
}: CardVfxOverlayProps) {
  const text = useDisplayText();
  const [positions, setPositions] = useState<Record<string, { start: { x: number; y: number }; center: { x: number; y: number }; target?: { x: number; y: number } }>>({});
  const [impactCoords, setImpactCoords] = useState<Record<string, { x: number; y: number }>>({});

  // Cập nhật tọa độ của các FlyingCard
  useEffect(() => {
    const container = boardContainerRef.current;
    if (!container) return;
    const containerRect = container.getBoundingClientRect();

    const centerEl = container.querySelector('#nativeProcessingArea') || container.querySelector('.board-center');
    const centerPoint = centerEl
      ? {
          x: centerEl.getBoundingClientRect().left + centerEl.getBoundingClientRect().width / 2 - containerRect.left,
          y: centerEl.getBoundingClientRect().top + centerEl.getBoundingClientRect().height / 2 - containerRect.top,
        }
      : { x: containerRect.width / 2, y: containerRect.height / 2 };

    const newPos: Record<string, { start: { x: number; y: number }; center: { x: number; y: number }; target?: { x: number; y: number } }> = {};

    for (const card of flyingCards) {
      // Tìm vị trí người ra bài
      const fromEl = typeof document !== 'undefined'
        ? (document.querySelector(`[data-player-id="${card.fromPlayerId}"]`) ||
           document.querySelector('.board-local-seat'))
        : null;
      const startPoint = fromEl
        ? {
            x: fromEl.getBoundingClientRect().left + fromEl.getBoundingClientRect().width / 2 - containerRect.left,
            y: fromEl.getBoundingClientRect().top + fromEl.getBoundingClientRect().height / 2 - containerRect.top,
          }
        : { x: containerRect.width / 2, y: containerRect.height * 0.85 };

      // Tìm vị trí mục tiêu đầu tiên (nếu có)
      let targetPoint: { x: number; y: number } | undefined;
      if (card.toPlayerIds && card.toPlayerIds.length > 0) {
        const toEl = typeof document !== 'undefined'
          ? (document.querySelector(`[data-player-id="${card.toPlayerIds[0]}"]`) ||
             document.querySelector(`.board-opponents [data-seat-id="${card.toPlayerIds[0]}"]`))
          : null;
        if (toEl) {
          targetPoint = {
            x: toEl.getBoundingClientRect().left + toEl.getBoundingClientRect().width / 2 - containerRect.left,
            y: toEl.getBoundingClientRect().top + toEl.getBoundingClientRect().height / 2 - containerRect.top,
          };
        }
      }

      newPos[card.id] = {
        start: startPoint,
        center: centerPoint,
        target: targetPoint,
      };
    }

    setPositions(newPos);
  }, [flyingCards, boardContainerRef]);

  // Cập nhật tọa độ của các ImpactVfx
  useEffect(() => {
    const container = boardContainerRef.current;
    if (!container) return;
    const containerRect = container.getBoundingClientRect();

    const newImpacts: Record<string, { x: number; y: number }> = {};
    for (const imp of impacts) {
      const el = typeof document !== 'undefined'
        ? (document.querySelector(`[data-player-id="${imp.targetPlayerId}"]`) ||
           document.querySelector('.board-local-seat'))
        : null;
      if (el) {
        const rect = el.getBoundingClientRect();
        newImpacts[imp.id] = {
          x: rect.left + rect.width / 2 - containerRect.left,
          y: rect.top + rect.height / 2 - containerRect.top,
        };
      } else {
        newImpacts[imp.id] = {
          x: containerRect.width / 2,
          y: containerRect.height / 2,
        };
      }
    }
    setImpactCoords(newImpacts);
  }, [impacts, boardContainerRef]);

  // Âm thanh khi có FlyingCard xuất hiện
  useEffect(() => {
    for (const card of flyingCards) {
      soundManager.playFlySound();
      soundManager.playCardVoice(card.cardName, 'male');
    }
  }, [flyingCards]);

  // Âm thanh khi có Impact xuất hiện
  useEffect(() => {
    for (const imp of impacts) {
      if (imp.kind === 'slash') soundManager.playDamageSound('normal_damage', imp.damageAmount || 1);
      else if (imp.kind === 'fire_slash') soundManager.playDamageSound('fire_damage', imp.damageAmount || 1);
      else if (imp.kind === 'thunder_slash' || imp.kind === 'lightning') soundManager.playDamageSound('thunder_damage', imp.damageAmount || 1);
      else if (imp.kind === 'jink') soundManager.playJinkSound('male');
      else if (imp.kind === 'peach') soundManager.playPeachSound('male');
      else if (imp.kind === 'analeptic') soundManager.playAnalepticSound('male');
      else if (imp.kind === 'nullification') soundManager.playNullifySound('male');
    }
  }, [impacts]);

  return (
    <div
      className="sg-card-vfx-overlay"
      aria-hidden="true"
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        pointerEvents: 'none',
        zIndex: 90,
        overflow: 'hidden',
      }}
    >
      {/* 1. Render các lá bài đang bay */}
      {flyingCards.map((card) => {
        const pos = positions[card.id];
        if (!pos) return null;

        const category = getCardCategory(card.cardName);
        const hasArt = CATALOG_CARD_ART_NAMES.has(card.cardName);
        const artUrl = hasArt ? catalogCardArtUrl(card.cardName) : null;
        const suitInfo = card.suit ? getSuitInfo(card.suit) : null;
        const rankStr = formatRank(card.number);

        return (
          <div
            key={card.id}
            className={`vfx-flying-card phase-${card.phase} ${category.className}`}
            style={{
              '--start-x': `${pos.start.x}px`,
              '--start-y': `${pos.start.y}px`,
              '--center-x': `${pos.center.x}px`,
              '--center-y': `${pos.center.y}px`,
              '--target-x': pos.target ? `${pos.target.x}px` : `${pos.center.x}px`,
              '--target-y': pos.target ? `${pos.target.y}px` : `${pos.center.y}px`,
            } as React.CSSProperties}
            onAnimationEnd={(e) => {
              if (e.target === e.currentTarget) {
                onFlyingCardDone(card.id);
              }
            }}
          >
            <div className="vfx-card-inner">
              <div className="vfx-card-header">
                {suitInfo && (
                  <span className={`vfx-card-suit ${suitInfo.colorClass}`}>
                    {suitInfo.symbol} {rankStr}
                  </span>
                )}
                <span className="vfx-card-name">{text(card.cardName)}</span>
              </div>
              <div className="vfx-card-body">
                {artUrl ? (
                  <img src={artUrl} alt={text(card.cardName)} className="vfx-card-art-img" />
                ) : (
                  <span className="vfx-card-symbol">🎴</span>
                )}
              </div>
            </div>
          </div>
        );
      })}

      {/* 2. Render các hiệu ứng va chạm (Impacts) */}
      {impacts.map((imp) => {
        const coord = impactCoords[imp.id];
        if (!coord) return null;

        // Native anim mapping
        const isNativeSlash = imp.kind === 'slash';
        const isNativeFireSlash = imp.kind === 'fire_slash';
        const isNativeThunderSlash = imp.kind === 'thunder_slash' || imp.kind === 'lightning';
        const isNativeJink = imp.kind === 'jink';
        const isNativePeach = imp.kind === 'peach';
        const isNativeAnaleptic = imp.kind === 'analeptic';

        return (
          <div
            key={imp.id}
            className={`vfx-impact-container kind-${imp.kind}`}
            style={{
              position: 'absolute',
              left: `${coord.x}px`,
              top: `${coord.y}px`,
              transform: 'translate(-50%, -50%)',
            }}
            onAnimationEnd={(e) => {
              if (e.target === e.currentTarget && !isNativeSlash && !isNativeFireSlash && !isNativeThunderSlash && !isNativeJink && !isNativePeach && !isNativeAnaleptic) {
                onImpactDone(imp.id);
              }
            }}
          >
            {/* Native FreeKill Frame Animations */}
            {isNativeSlash && (
              <NativeVfxAnim
                animName="slash"
                scale={1.25}
                intervalMs={42}
                onFinished={() => onImpactDone(imp.id)}
              />
            )}

            {isNativeFireSlash && (
              <NativeVfxAnim
                animName="fire__slash"
                scale={1.25}
                intervalMs={42}
                onFinished={() => onImpactDone(imp.id)}
              />
            )}

            {isNativeThunderSlash && (
              <NativeVfxAnim
                animName="thunder__slash"
                scale={1.25}
                intervalMs={42}
                onFinished={() => onImpactDone(imp.id)}
              />
            )}

            {isNativeJink && (
              <NativeVfxAnim
                animName="jink"
                scale={1.15}
                intervalMs={40}
                onFinished={() => onImpactDone(imp.id)}
              />
            )}

            {isNativePeach && (
              <NativeVfxAnim
                animName="peach"
                scale={1.2}
                intervalMs={45}
                onFinished={() => onImpactDone(imp.id)}
              />
            )}

            {isNativeAnaleptic && (
              <NativeVfxAnim
                animName="analeptic"
                scale={1.2}
                intervalMs={45}
                onFinished={() => onImpactDone(imp.id)}
              />
            )}

            {/* Hiệu ứng Vô Giải Khả Kích */}
            {imp.kind === 'nullification' && (
              <div className="vfx-nullify-yin-yang">
                <div className="vfx-bagua-symbol">☯</div>
                <div className="vfx-nullify-text">VÔ HIỆU</div>
              </div>
            )}

            {/* Hiệu ứng va chạm phổ thông */}
            {imp.kind === 'generic_impact' && (
              <div className="vfx-generic-spark">
                <div className="vfx-spark-circle" />
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

export const CardFlyOverlay = CardVfxOverlay;
