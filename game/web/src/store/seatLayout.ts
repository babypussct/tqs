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
    { left: '50%', top: '13%' },
  ],
  4: [
    { left: '86%', top: '38%' },
    { left: '50%', top: '13%' },
    { left: '14%', top: '38%' },
  ],
  6: [
    { left: '86%', top: '46%' },
    { left: '73%', top: '15%' },
    { left: '50%', top: '13%' },
    { left: '27%', top: '15%' },
    { left: '14%', top: '46%' },
  ],
  8: [
    { left: '88%', top: '48%' },
    { left: '88%', top: '29%' },
    { left: '70%', top: '13%' },
    { left: '50%', top: '11%' },
    { left: '30%', top: '13%' },
    { left: '12%', top: '29%' },
    { left: '12%', top: '48%' },
  ],
  10: [
    { left: '89%', top: '50%' },
    { left: '89%', top: '34%' },
    { left: '80%', top: '18%' },
    { left: '64%', top: '11%' },
    { left: '50%', top: '10%' },
    { left: '36%', top: '11%' },
    { left: '20%', top: '18%' },
    { left: '11%', top: '34%' },
    { left: '11%', top: '50%' },
  ],
};

const DETERMINISTIC_LANDSCAPE_SEATS: Record<number, Array<{ left: string; top: string }>> = {
  2: [
    { left: '50%', top: '12%' },
  ],
  4: [
    { left: '86%', top: '38.5%' },
    { left: '50%', top: '12%' },
    { left: '14%', top: '38.5%' },
  ],
  6: [
    { left: '88%', top: '44%' },
    { left: '74%', top: '15%' },
    { left: '50%', top: '12%' },
    { left: '26%', top: '15%' },
    { left: '12%', top: '44%' },
  ],
  8: [
    { left: '89.5%', top: '52%' },
    { left: '89.5%', top: '30%' },
    { left: '73%', top: '12%' },
    { left: '50%', top: '11%' },
    { left: '27%', top: '12%' },
    { left: '10.5%', top: '30%' },
    { left: '10.5%', top: '52%' },
  ],
  10: [
    { left: '91%', top: '52%' },
    { left: '91%', top: '32%' },
    { left: '79%', top: '15%' },
    { left: '62%', top: '11%' },
    { left: '50%', top: '10%' },
    { left: '38%', top: '11%' },
    { left: '21%', top: '15%' },
    { left: '9%', top: '32%' },
    { left: '9%', top: '52%' },
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
): React.CSSProperties {
  const scale = getScale(totalSeats, isMobile);
  const table = isMobile ? DETERMINISTIC_PORTRAIT_SEATS : DETERMINISTIC_LANDSCAPE_SEATS;
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
      top: isMobile ? '13%' : '12%',
      transform: `translate(-50%, -50%) scale(${scale})`,
    };
  }

  const cX = 50;
  const cY = isMobile ? 38 : 38.5;
  const rX = isMobile ? 38 : 42.5;
  const rY = isMobile ? 24.5 : 28;
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
}: DeriveSeatViewModelsParams): {
  selfSeat: SeatViewModel | null;
  opponentSeats: SeatViewModel[];
  allSeats: SeatViewModel[];
} {
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
      positionStyle: getDeterministicSeatPosition(opponentIndex, totalSeats, isMobile),
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
