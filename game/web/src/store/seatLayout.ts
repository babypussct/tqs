import type React from 'react';
import { relativeSeatOrder, serverSeatNumbers, type BoardPlayer } from './boardState';
import type { GameplayItem } from './gameplayState';

export interface SeatPosition {
  left: string;
  top: string;
  transform: string;
}

export interface SeatViewModel {
  playerId: number;
  serverSeatNumber: number;
  visualIndex: number;
  isSelf: boolean;
  isActive: boolean;
  isTargetable: boolean;
  isSelectedTarget: boolean;
  isPrivate: boolean;
  positionStyle: React.CSSProperties;
}

/**
 * Deterministic seat position coordinates for 2, 4, 6, 8, 10-player Quốc Chiến tables.
 * Each profile defines coordinates for the (totalSeats - 1) opponents, clockwise
 * from self's immediate right, placing self deterministically at the bottom dashboard.
 */
const DETERMINISTIC_PORTRAIT_SEATS: Record<number, Array<{ left: string; top: string }>> = {
  2: [
    { left: '50%', top: '22%' },
  ],
  4: [
    { left: '86%', top: '48%' },
    { left: '50%', top: '21%' },
    { left: '14%', top: '48%' },
  ],
  6: [
    { left: '87%', top: '54%' },
    { left: '73%', top: '21%' },
    { left: '50%', top: '19%' },
    { left: '27%', top: '21%' },
    { left: '13%', top: '54%' },
  ],
  8: [
    { left: '88%', top: '62%' },
    { left: '88%', top: '36%' },
    { left: '72%', top: '20%' },
    { left: '50%', top: '18%' },
    { left: '28%', top: '20%' },
    { left: '12%', top: '36%' },
    { left: '12%', top: '62%' },
  ],
  10: [
    { left: '89%', top: '62%' },
    { left: '89%', top: '44%' },
    { left: '82%', top: '24%' },
    { left: '66%', top: '16%' },
    { left: '50%', top: '15%' },
    { left: '34%', top: '16%' },
    { left: '18%', top: '24%' },
    { left: '11%', top: '44%' },
    { left: '11%', top: '62%' },
  ],
};

const DETERMINISTIC_LANDSCAPE_SEATS: Record<number, Array<{ left: string; top: string }>> = {
  2: [
    { left: '50%', top: '19%' },
  ],
  4: [
    { left: '86%', top: '42%' },
    { left: '50%', top: '19%' },
    { left: '14%', top: '42%' },
  ],
  6: [
    { left: '88%', top: '46%' },
    { left: '72%', top: '24%' },
    { left: '50%', top: '20%' },
    { left: '28%', top: '24%' },
    { left: '12%', top: '46%' },
  ],
  8: [
    { left: '91%', top: '46%' },
    { left: '80%', top: '26%' },
    { left: '65%', top: '19%' },
    { left: '50%', top: '17%' },
    { left: '35%', top: '19%' },
    { left: '20%', top: '26%' },
    { left: '9%', top: '46%' },
  ],
  10: [
    { left: '92%', top: '48%' },
    { left: '83%', top: '30%' },
    { left: '72%', top: '21%' },
    { left: '61%', top: '17%' },
    { left: '50%', top: '15%' },
    { left: '39%', top: '17%' },
    { left: '28%', top: '21%' },
    { left: '17%', top: '30%' },
    { left: '8%', top: '48%' },
  ],
};

function getScale(totalSeats: number, isMobile: boolean): number {
  if (isMobile) {
    if (totalSeats >= 10) return 0.50;
    if (totalSeats >= 8) return 0.62;
    if (totalSeats >= 6) return 0.70;
    if (totalSeats >= 4) return 0.75;
    return 0.88;
  }
  if (totalSeats >= 10) return 0.60;
  if (totalSeats >= 8) return 0.72;
  if (totalSeats >= 6) return 0.80;
  if (totalSeats >= 4) return 0.88;
  return 1.0;
}

/**
 * Returns the deterministic position style for an opponent in the table view.
 * Opponents are indexed clockwise starting from Self's right.
 */
export function getDeterministicSeatPosition(
  opponentIndex: number,
  totalSeats: number,
  isMobile: boolean,
  isPortrait: boolean = isMobile,
): React.CSSProperties {
  const scale = getScale(totalSeats, isMobile);
  const table = isPortrait ? DETERMINISTIC_PORTRAIT_SEATS : DETERMINISTIC_LANDSCAPE_SEATS;
  const profile = table[totalSeats];

  if (profile && opponentIndex >= 0 && opponentIndex < profile.length) {
    const coord = profile[opponentIndex];
    return {
      left: coord.left,
      top: coord.top,
      transform: `translate(-50%, -50%) scale(${scale})`,
    };
  }

  // Graceful fallback for non-standard seat counts (odd numbers or > 10)
  if (totalSeats <= 2) {
    return {
      left: '50%',
      top: isPortrait ? '13%' : '22%',
      transform: `translate(-50%, -50%) scale(${scale})`,
    };
  }

  const cX = 50;
  const cY = isPortrait ? 38 : 38.5;
  const rX = isPortrait ? 38 : 42.5;
  const rY = isPortrait ? 24.5 : 28;
  const angleStep = 360 / totalSeats;
  const deg = 90 - (opponentIndex + 1) * angleStep;
  const rad = (deg * Math.PI) / 180;
  const x = cX + rX * Math.cos(rad);
  const y = cY + rY * Math.sin(rad);

  return {
    left: `${x.toFixed(2)}%`,
    top: `${y.toFixed(2)}%`,
    transform: `translate(-50%, -50%) scale(${scale})`,
  };
}

/** Backwards-compatible export matching GameBoardScreen */
export const getOpponentPosition = getDeterministicSeatPosition;

export interface DeriveSeatViewModelsParams {
  boardSeats: number[];
  playerIds: number[];
  ownId: number | null;
  boardPlayers: Record<number, BoardPlayer>;
  gameplayActive: boolean;
  targetItems?: Record<string, GameplayItem>;
  isMobile: boolean;
  isPortrait?: boolean;
}

/**
 * Derives strongly-typed SeatViewModels maintaining server seat number,
 * relative visual index, privacy state, targetable state, and active state.
 * Never derives server seat or identity from visual position.
 */
export function deriveSeatViewModels({
  boardSeats,
  playerIds,
  ownId,
  boardPlayers,
  gameplayActive,
  targetItems,
  isMobile,
  isPortrait,
}: DeriveSeatViewModelsParams): {
  selfSeat: SeatViewModel | null;
  opponentSeats: SeatViewModel[];
  allSeats: SeatViewModel[];
} {
  const resolvedPortrait = isPortrait ?? isMobile;
  const seatOrder = relativeSeatOrder(boardSeats, playerIds, ownId);
  const absoluteSeatNumbers = serverSeatNumbers(boardSeats, playerIds);
  const totalSeats = Math.max(2, seatOrder.length);

  const isPlayerActive = (id: number): boolean => {
    const phase = boardPlayers[id]?.phase;
    return phase !== null && phase !== undefined && ![0, 8, 9, 'NotActive', 'PhaseNone'].includes(phase);
  };

  const getTargetItem = (id: number): GameplayItem | undefined => {
    return gameplayActive && targetItems ? targetItems[String(id)] : undefined;
  };

  const allSeats: SeatViewModel[] = [];
  let selfSeat: SeatViewModel | null = null;
  const opponentSeats: SeatViewModel[] = [];

  const others = seatOrder.filter((id) => id !== ownId);

  // Derive opponents
  others.forEach((id, opponentIndex) => {
    const target = getTargetItem(id);
    const serverSeat = absoluteSeatNumbers.get(id) ?? opponentIndex + 1;
    const model: SeatViewModel = {
      playerId: id,
      serverSeatNumber: serverSeat,
      visualIndex: opponentIndex + 1,
      isSelf: false,
      isActive: isPlayerActive(id),
      isTargetable: !!target?.enabled,
      isSelectedTarget: !!target?.selected,
      isPrivate: false,
      positionStyle: getDeterministicSeatPosition(opponentIndex, totalSeats, isMobile, resolvedPortrait),
    };
    opponentSeats.push(model);
    allSeats.push(model);
  });

  // Derive self
  if (ownId !== null && seatOrder.includes(ownId)) {
    const target = getTargetItem(ownId);
    const serverSeat = absoluteSeatNumbers.get(ownId) ?? seatOrder.indexOf(ownId) + 1;
    selfSeat = {
      playerId: ownId,
      serverSeatNumber: serverSeat,
      visualIndex: 0,
      isSelf: true,
      isActive: isPlayerActive(ownId),
      isTargetable: !!target?.enabled,
      isSelectedTarget: !!target?.selected,
      isPrivate: true,
      positionStyle: {},
    };
    allSeats.push(selfSeat);
  }

  return { selfSeat, opponentSeats, allSeats };
}
