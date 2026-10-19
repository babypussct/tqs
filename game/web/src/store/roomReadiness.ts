import type { RoomPlayer } from './gameStore';

export interface RoomReadiness {
  isFull: boolean;
  isAllReady: boolean;
  canReady: boolean;
  canStart: boolean;
  canAddBot: boolean;
  missingReadyCount: number;
}

export interface RoomPoolSummary {
  generals: number;
  cards: number;
}

/** Explain a disabled Create Room affordance from the current Lua pool preview. */
export function roomPoolDisabledReason(
  pool: RoomPoolSummary | null,
  capacity: number,
  qaError?: string,
  generalNum = 5,
): string | null {
  if (qaError) return qaError;
  if (!pool) return 'Không thể kiểm tra bể tướng và bể bài từ Lua.';
  const requiredGenerals = capacity * generalNum;
  const requiredCards = capacity * 4;
  const missing: string[] = [];
  if (pool.generals < requiredGenerals) {
    missing.push(`thiếu tướng (${pool.generals}/${requiredGenerals})`);
  }
  if (pool.cards < requiredCards) {
    missing.push(`thiếu bài (${pool.cards}/${requiredCards})`);
  }
  return missing.length ? `Chưa thể tạo phòng: ${missing.join(' và ')}.` : null;
}

/** Explain a disabled Start affordance without inventing a second readiness rule. */
export function roomStartDisabledReason(readiness: RoomReadiness, isObserver: boolean): string | null {
  if (isObserver) return 'Người quan sát không thể bắt đầu trận.';
  if (readiness.canStart) return null;
  if (!readiness.isFull) return 'Cần đủ người chơi trong tất cả ghế trước khi bắt đầu.';
  if (readiness.missingReadyCount > 0) {
    return `Còn ${readiness.missingReadyCount} người chơi chưa sẵn sàng.`;
  }
  return 'Chỉ chủ phòng mới có thể bắt đầu trận.';
}

/**
 * Derive the waiting-room affordances from server-owned room state.
 *
 * FreeKill's native WaitingRoom ignores the owner's ready flag and only
 * considers non-owner seats. It still requires every seat to be occupied
 * before the owner can start. Keeping this calculation pure makes the React
 * affordances testable without inventing a client-side game rule.
 */
export function deriveRoomReadiness(
  players: readonly RoomPlayer[],
  capacity: number,
  ownId: number | null,
  isObserver: boolean,
): RoomReadiness {
  const self = ownId === null ? undefined : players.find((player) => player.id === ownId);
  const validCapacity = Number.isInteger(capacity) && capacity > 0;
  const isFull = validCapacity && players.length >= capacity;
  const missingReadyCount = players.filter((player) => !player.owner && !player.ready).length;
  const isAllReady = isFull && missingReadyCount === 0;

  return {
    isFull,
    isAllReady,
    canReady: !!self && !self.owner && !isObserver,
    canStart: !!self?.owner && !isObserver && isFull && isAllReady,
    canAddBot: !!self?.owner && !isObserver && !isFull,
    missingReadyCount,
  };
}

