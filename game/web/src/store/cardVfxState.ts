import { useState, useCallback, useRef } from 'react';
import type { NativeVfxEvent } from './nativeVfxEvents';

/**
 * Card VFX and Animation State Management.
 * Coordinates card flying animations, target indicator curves, and combat impact VFX.
 */

export type ImpactVfxKind =
  | 'slash'
  | 'fire_slash'
  | 'thunder_slash'
  | 'jink'
  | 'peach'
  | 'analeptic'
  | 'nullification'
  | 'lightning'
  | 'generic_impact';

export type AvatarReactionType = 'hit-shake' | 'dodge-slide' | 'heal-glow';

export interface FlyingCardEvent {
  id: string;
  fromPlayerId: number;
  toPlayerIds: number[];
  cardName: string;
  /** Public card-model hints, when the same card was projected by Lua. */
  trueName?: string;
  extension?: string;
  picName?: string;
  suit?: number;
  number?: number;
  createdAt: number;
  phase: 'fly_to_center' | 'holding' | 'projectile_to_target' | 'done';
}

export interface CardAssetHint {
  trueName?: string;
  extension?: string;
  picName?: string;
}

export interface ImpactVfxEvent {
  id: string;
  targetPlayerId: number;
  kind: ImpactVfxKind;
  createdAt: number;
  damageAmount?: number;
}

export interface TargetingLine {
  fromPlayerId: number;
  toPlayerId: number;
}

export interface ActiveCardTargetIndicator {
  id: string;
  fromPlayerId: number;
  toPlayerIds: number[];
  cardName: string;
  createdAt: number;
  durationMs: number;
}

export interface CardVfxState {
  flyingCards: FlyingCardEvent[];
  impacts: ImpactVfxEvent[];
  avatarReactions: Record<number, AvatarReactionType>;
  activeTargetIndicators: ActiveCardTargetIndicator[];
}

export function createInitialVfxState(): CardVfxState {
  return {
    flyingCards: [],
    impacts: [],
    avatarReactions: {},
    activeTargetIndicators: [],
  };
}

/**
 * Deterministic seat percentages for mathematical coordinate calculations.
 */
export const PORTRAIT_SEAT_PERCENTAGES: Record<number, Array<{ left: number; top: number }>> = {
  2: [{ left: 50, top: 22 }],
  4: [
    { left: 86, top: 48 },
    { left: 50, top: 21 },
    { left: 14, top: 48 },
  ],
  6: [
    { left: 87, top: 54 },
    { left: 73, top: 21 },
    { left: 50, top: 19 },
    { left: 27, top: 21 },
    { left: 13, top: 54 },
  ],
  8: [
    { left: 88, top: 62 },
    { left: 88, top: 36 },
    { left: 72, top: 20 },
    { left: 50, top: 18 },
    { left: 28, top: 20 },
    { left: 12, top: 36 },
    { left: 12, top: 62 },
  ],
  10: [
    { left: 89, top: 62 },
    { left: 89, top: 44 },
    { left: 82, top: 24 },
    { left: 66, top: 16 },
    { left: 50, top: 15 },
    { left: 34, top: 16 },
    { left: 18, top: 24 },
    { left: 11, top: 44 },
    { left: 11, top: 62 },
  ],
};

export const LANDSCAPE_SEAT_PERCENTAGES: Record<number, Array<{ left: number; top: number }>> = {
  2: [{ left: 50, top: 19 }],
  4: [
    { left: 86, top: 42 },
    { left: 50, top: 19 },
    { left: 14, top: 42 },
  ],
  6: [
    { left: 88, top: 46 },
    { left: 72, top: 24 },
    { left: 50, top: 20 },
    { left: 28, top: 24 },
    { left: 12, top: 46 },
  ],
  8: [
    { left: 91, top: 46 },
    { left: 80, top: 26 },
    { left: 65, top: 19 },
    { left: 50, top: 17 },
    { left: 35, top: 19 },
    { left: 20, top: 26 },
    { left: 9, top: 46 },
  ],
  10: [
    { left: 92, top: 48 },
    { left: 83, top: 30 },
    { left: 72, top: 21 },
    { left: 61, top: 17 },
    { left: 50, top: 15 },
    { left: 39, top: 17 },
    { left: 28, top: 21 },
    { left: 17, top: 30 },
    { left: 8, top: 48 },
  ],
};

export interface SeatCenterCoordOptions {
  isLandscape: boolean;
  seatIndex?: number;
  totalSeats?: number;
  isSelf?: boolean;
  containerWidth: number;
  containerHeight: number;
}

/**
 * Calculates deterministic seat center coordinates on both portrait and landscape layouts.
 */
export function getSeatCenterCoordinates({
  isLandscape,
  seatIndex = 0,
  totalSeats = 4,
  isSelf = false,
  containerWidth,
  containerHeight,
}: SeatCenterCoordOptions): { x: number; y: number } {
  if (isSelf) {
    if (isLandscape) {
      // Landscape: Cột 1 (dashboard left avatar)
      return {
        x: Math.min(52, containerWidth * 0.1),
        y: containerHeight * 0.86,
      };
    }
    // Portrait: Khung avatar bản thân ở góc trái dưới
    return {
      x: containerWidth * 0.14,
      y: containerHeight * 0.92,
    };
  }

  const clampedTotal = [2, 4, 6, 8, 10].includes(totalSeats) ? totalSeats : 4;
  const table = isLandscape ? LANDSCAPE_SEAT_PERCENTAGES : PORTRAIT_SEAT_PERCENTAGES;
  const seatList = table[clampedTotal] || table[4];
  const targetSeat = seatList[Math.min(seatIndex, seatList.length - 1)] || { left: 50, top: 20 };

  return {
    x: (targetSeat.left / 100) * containerWidth,
    y: (targetSeat.top / 100) * containerHeight,
  };
}

/**
 * Maps raw card name (e.g. "thunder__slash", "sa__blade") to standard impact VFX kind.
 */
export function resolveCardImpactKind(cardName: string): ImpactVfxKind {
  const normalized = cardName.toLowerCase();
  if (normalized.includes('thunder__slash') || normalized === 'lightning') {
    return 'thunder_slash';
  }
  if (normalized.includes('fire__slash') || normalized.includes('burning_camps') || normalized.includes('fire_attack')) {
    return 'fire_slash';
  }
  if (
    normalized.includes('slash') ||
    normalized.includes('blade') ||
    normalized.includes('sword') ||
    normalized.includes('spear') ||
    normalized.includes('axe') ||
    normalized.includes('halberd') ||
    normalized.includes('duel') ||
    normalized.includes('savage_assault') ||
    normalized.includes('archery_attack')
  ) {
    return 'slash';
  }
  if (normalized.includes('jink')) {
    return 'jink';
  }
  if (normalized.includes('peach') || normalized.includes('god_salvation')) {
    return 'peach';
  }
  if (normalized.includes('analeptic') || normalized.includes('wine')) {
    return 'analeptic';
  }
  if (normalized.includes('nullification')) {
    return 'nullification';
  }
  return 'generic_impact';
}

/**
 * Extracts card name, suit, and rank from token strings like "slash[spade:7]" or "fire__slash".
 */
export function parseCardToken(token: string): { name: string; suit?: number; number?: number } {
  if (!token) return { name: '' };
  const match = token.match(/^([a-zA-Z0-9_]+)(?:\[([a-zA-Z0-9_]+):([a-zA-Z0-9]+)\])?$/);
  if (!match) {
    const cleanName = token.replace(/\[.*$/, '').trim();
    return { name: cleanName || token };
  }
  const name = match[1];
  let suit: number | undefined;
  if (match[2]) {
    const s = match[2].toLowerCase();
    if (s.includes('spade')) suit = 1;
    else if (s.includes('club')) suit = 2;
    else if (s.includes('heart')) suit = 3;
    else if (s.includes('diamond')) suit = 4;
  }
  let number: number | undefined;
  if (match[3]) {
    const rawNum = match[3].toUpperCase();
    if (rawNum === 'A') number = 1;
    else if (rawNum === 'J') number = 11;
    else if (rawNum === 'Q') number = 12;
    else if (rawNum === 'K') number = 13;
    else {
      const n = Number(rawNum);
      if (Number.isFinite(n)) number = n;
    }
  }
  const result: { name: string; suit?: number; number?: number } = { name };
  if (suit !== undefined) result.suit = suit;
  if (number !== undefined) result.number = number;
  return result;
}

export interface ParsedVfxFromLog {
  flyingCard?: {
    fromPlayerId: number;
    toPlayerIds: number[];
    cardName: string;
    suit?: number;
    number?: number;
  };
  impact?: {
    targetPlayerId: number;
    kind: ImpactVfxKind;
    damageAmount?: number;
  };
  avatarReaction?: {
    playerId: number;
    type: AvatarReactionType;
  };
}

/**
 * Parses native GameLog strings into card visual events and avatar reactions.
 */
export function parseVfxFromGameLog(rawLog: string): ParsedVfxFromLog | null {
  if (!rawLog || typeof rawLog !== 'string') return null;
  const parts = rawLog.split(':');
  const [tag, p1, p2] = parts;

  if (tag === '#UseCardToTargets') {
    const fromId = Number(p1);
    const rawCard = parts.slice(3).join(':') || p2;
    const parsedCard = parseCardToken(rawCard);
    const toIds = (p2 || '').split(',').map(Number).filter((n) => Number.isInteger(n));
    if (Number.isInteger(fromId) && parsedCard.name) {
      const flyingCard: {
        fromPlayerId: number;
        toPlayerIds: number[];
        cardName: string;
        suit?: number;
        number?: number;
      } = {
        fromPlayerId: fromId,
        toPlayerIds: toIds.length > 0 ? toIds : [],
        cardName: parsedCard.name,
      };
      if (parsedCard.suit !== undefined) flyingCard.suit = parsedCard.suit;
      if (parsedCard.number !== undefined) flyingCard.number = parsedCard.number;

      return { flyingCard };
    }
  }

  if (tag === '#UseCard') {
    const fromId = Number(p1);
    const rawCard = parts.slice(2).join(':');
    const parsedCard = parseCardToken(rawCard);
    if (Number.isInteger(fromId) && parsedCard.name) {
      const flyingCard: {
        fromPlayerId: number;
        toPlayerIds: number[];
        cardName: string;
        suit?: number;
        number?: number;
      } = {
        fromPlayerId: fromId,
        toPlayerIds: [],
        cardName: parsedCard.name,
      };
      if (parsedCard.suit !== undefined) flyingCard.suit = parsedCard.suit;
      if (parsedCard.number !== undefined) flyingCard.number = parsedCard.number;
      return { flyingCard };
    }
  }

  if (tag === '#ResponsePlayCard') {
    const fromId = Number(p1);
    const rawCard = parts.slice(2).join(':');
    const parsedCard = parseCardToken(rawCard);
    if (Number.isInteger(fromId) && parsedCard.name) {
      const kind = resolveCardImpactKind(parsedCard.name);
      const flyingCard: {
        fromPlayerId: number;
        toPlayerIds: number[];
        cardName: string;
        suit?: number;
        number?: number;
      } = {
        fromPlayerId: fromId,
        toPlayerIds: [],
        cardName: parsedCard.name,
      };
      if (parsedCard.suit !== undefined) flyingCard.suit = parsedCard.suit;
      if (parsedCard.number !== undefined) flyingCard.number = parsedCard.number;
      // Only native LogEvent/Damage owns hit-shake and damage audio.
      return kind === 'jink' ? {
        flyingCard,
        impact: { targetPlayerId: fromId, kind: 'jink' },
        avatarReaction: { playerId: fromId, type: 'dodge-slide' },
      } : { flyingCard };
    }
  }

  if (tag === '#HpRecover') {
    // #HpRecover:player:num
    const playerId = Number(p1);
    if (Number.isInteger(playerId)) {
      return {
        impact: {
          targetPlayerId: playerId,
          kind: 'peach',
        },
        avatarReaction: {
          playerId,
          type: 'heal-glow',
        },
      };
    }
  }

  if (tag === '#UseCardNullified') {
    const fromId = Number(p1);
    if (Number.isInteger(fromId)) {
      return {
        impact: {
          targetPlayerId: fromId,
          kind: 'nullification',
        },
      };
    }
  }

  return null;
}

/**
 * Hook managing the visual effects queue, flying card lifecycle, and avatar reactions.
 */
export function useCardVfx() {
  const [flyingCards, setFlyingCards] = useState<FlyingCardEvent[]>([]);
  const [impacts, setImpacts] = useState<ImpactVfxEvent[]>([]);
  const [avatarReactions, setAvatarReactions] = useState<Record<number, AvatarReactionType>>({});
  const [activeTargetIndicators, setActiveTargetIndicators] = useState<ActiveCardTargetIndicator[]>([]);
  const lastProcessedLogCount = useRef<number>(0);
  const lastNativeSequence = useRef(0);

  const triggerCardFly = useCallback((card: Omit<FlyingCardEvent, 'id' | 'createdAt' | 'phase'>) => {
    const id = `fly-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    setFlyingCards((prev) => [
      ...prev,
      {
        ...card,
        id,
        createdAt: Date.now(),
        phase: 'fly_to_center',
      },
    ]);
    return id;
  }, []);

  const triggerCombatImpact = useCallback((impact: Omit<ImpactVfxEvent, 'id' | 'createdAt'>) => {
    const id = `impact-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    setImpacts((prev) => [
      ...prev,
      {
        ...impact,
        id,
        createdAt: Date.now(),
      },
    ]);
    return id;
  }, []);

  const triggerAvatarReaction = useCallback((playerId: number, reaction: AvatarReactionType, durationMs = 400) => {
    setAvatarReactions((prev) => ({ ...prev, [playerId]: reaction }));
    const timer = setTimeout(() => {
      setAvatarReactions((prev) => {
        const next = { ...prev };
        if (next[playerId] === reaction) {
          delete next[playerId];
        }
        return next;
      });
    }, durationMs);
    return () => clearTimeout(timer);
  }, []);

  const triggerActiveTargetIndicator = useCallback((indicator: Omit<ActiveCardTargetIndicator, 'id' | 'createdAt'>) => {
    const id = `ind-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    const newInd: ActiveCardTargetIndicator = {
      ...indicator,
      id,
      createdAt: Date.now(),
    };
    setActiveTargetIndicators((prev) => [...prev, newInd]);
    const timer = setTimeout(() => {
      setActiveTargetIndicators((prev) => prev.filter((i) => i.id !== id));
    }, indicator.durationMs || 2200);
    return () => clearTimeout(timer);
  }, []);

  const onFlyingCardDone = useCallback((id: string) => {
    setFlyingCards((prev) => prev.filter((c) => c.id !== id));
  }, []);

  const onImpactDone = useCallback((id: string) => {
    setImpacts((prev) => prev.filter((i) => i.id !== id));
  }, []);

  const processGameLogs = useCallback((logs: string[], cardAssetHints: Readonly<Record<string, CardAssetHint>> = {}) => {
    const enrichKnownCardAssets = () => {
      setFlyingCards((current) => {
        let changed = false;
        const next = current.map((card) => {
          const hint = cardAssetHints[card.cardName];
          if (!hint || (card.extension === hint.extension && card.picName === hint.picName && card.trueName === hint.trueName)) {
            return card;
          }
          changed = true;
          return { ...card, ...hint };
        });
        return changed ? next : current;
      });
    };
    if (logs.length <= lastProcessedLogCount.current) {
      enrichKnownCardAssets();
      if (logs.length < lastProcessedLogCount.current) {
        lastProcessedLogCount.current = logs.length;
      }
      return;
    }
    const newLogs = logs.slice(lastProcessedLogCount.current);
    lastProcessedLogCount.current = logs.length;

    const newFlying: FlyingCardEvent[] = [];
    const newImpacts: ImpactVfxEvent[] = [];
    const newReactions: Array<{ playerId: number; type: AvatarReactionType }> = [];

    newLogs.forEach((log, index) => {
      const parsed = parseVfxFromGameLog(log);
      if (!parsed) return;
      const baseId = `${Date.now()}-${index}-${Math.random().toString(36).slice(2, 6)}`;

      if (parsed.flyingCard) {
        const hint = cardAssetHints[parsed.flyingCard.cardName];
        newFlying.push({
          id: `fly-${baseId}`,
          fromPlayerId: parsed.flyingCard.fromPlayerId,
          toPlayerIds: parsed.flyingCard.toPlayerIds,
          cardName: parsed.flyingCard.cardName,
          trueName: hint?.trueName,
          extension: hint?.extension,
          picName: hint?.picName,
          suit: parsed.flyingCard.suit,
          number: parsed.flyingCard.number,
          createdAt: Date.now(),
          phase: 'fly_to_center',
        });
      }

      if (parsed.impact) {
        newImpacts.push({
          id: `impact-${baseId}`,
          targetPlayerId: parsed.impact.targetPlayerId,
          kind: parsed.impact.kind,
          createdAt: Date.now(),
          damageAmount: parsed.impact.damageAmount,
        });
      }

      if (parsed.avatarReaction) {
        newReactions.push(parsed.avatarReaction);
      }

    });

    if (newFlying.length > 0) {
      setFlyingCards((prev) => [...prev, ...newFlying]);
    }
    if (newImpacts.length > 0) {
      setImpacts((prev) => [...prev, ...newImpacts]);
    }
    if (newReactions.length > 0) {
      newReactions.forEach(({ playerId, type }) => {
        triggerAvatarReaction(playerId, type);
      });
    }
  }, [triggerAvatarReaction]);

  const processNativeEvents = useCallback((events: NativeVfxEvent[]) => {
    for (const event of events) {
      if (event.sequence <= lastNativeSequence.current) continue;
      lastNativeSequence.current = event.sequence;
      // Don't replay notifications retained before a board remount.
      if (Date.now() - event.createdAt > 1000) continue;
      if (event.kind === 'indicate') {
        triggerActiveTargetIndicator({ fromPlayerId: event.fromPlayerId,
          toPlayerIds: event.toPlayerIds, cardName: '', durationMs: 700 });
      } else if (event.kind === 'damage') {
        triggerCombatImpact({ targetPlayerId: event.targetPlayerId,
          kind: event.damageType === 'fire_damage' ? 'fire_slash'
            : event.damageType === 'thunder_damage' ? 'thunder_slash' : 'slash',
          damageAmount: event.damageNum });
        triggerAvatarReaction(event.targetPlayerId, 'hit-shake');
      }
    }
  }, [triggerActiveTargetIndicator, triggerCombatImpact, triggerAvatarReaction]);

  return {
    flyingCards,
    impacts,
    avatarReactions,
    activeTargetIndicators,
    triggerCardFly,
    triggerCombatImpact,
    triggerAvatarReaction,
    triggerActiveTargetIndicator,
    onFlyingCardDone,
    onImpactDone,
    processGameLogs,
    processNativeEvents,
    setFlyingCards,
    setImpacts,
  };
}
