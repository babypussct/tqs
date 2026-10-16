import assert from 'node:assert/strict';
import test from 'node:test';
import {
  deriveSeatViewModels,
  getDeterministicSeatPosition,
} from '../src/store/seatLayout';
import type { BoardPlayer } from '../src/store/boardState';

test('deterministic seat positions define valid coordinates for profiles 2, 4, 6, 8, 10', () => {
  for (const isMobile of [true, false]) {
    for (const totalSeats of [2, 4, 6, 8, 10]) {
      const positions: Array<{ left: number; top: number }> = [];
      const opponentCount = totalSeats - 1;

      for (let i = 0; i < opponentCount; i++) {
        const style = getDeterministicSeatPosition(i, totalSeats, isMobile);
        assert.ok(typeof style.left === 'string' && style.left.endsWith('%'), `left must be percentage for seat ${i}/${totalSeats}`);
        assert.ok(typeof style.top === 'string' && style.top.endsWith('%'), `top must be percentage for seat ${i}/${totalSeats}`);
        assert.ok(typeof style.transform === 'string' && style.transform.includes('scale'), `transform must include scale for seat ${i}/${totalSeats}`);

        const leftNum = parseFloat(style.left);
        const topNum = parseFloat(style.top);
        assert.ok(leftNum >= 5 && leftNum <= 95, `left position must be within viewport [5, 95]: got ${leftNum}`);
        assert.ok(topNum >= 8 && topNum <= 65, `top position must be within upper table bounds [8, 65]: got ${topNum}`);

        positions.push({ left: leftNum, top: topNum });
      }

      // Check no two opponents occupy the exact same coordinate
      for (let a = 0; a < positions.length; a++) {
        for (let b = a + 1; b < positions.length; b++) {
          const dx = Math.abs(positions[a].left - positions[b].left);
          const dy = Math.abs(positions[a].top - positions[b].top);
          const dist = Math.hypot(dx, dy);
          assert.ok(dist >= 5, `seats ${a} and ${b} for profile ${totalSeats} are too close (dist=${dist})`);
        }
      }
    }
  }
});

test('2-player seat profile positions opponent at top center', () => {
  const mobile = getDeterministicSeatPosition(0, 2, true);
  const desktop = getDeterministicSeatPosition(0, 2, false);
  assert.equal(mobile.left, '50%');
  assert.equal(desktop.left, '50%');
});

test('4-player seat profile positions opponents at right, top, left', () => {
  for (const isMobile of [true, false]) {
    const opp0 = getDeterministicSeatPosition(0, 4, isMobile);
    const opp1 = getDeterministicSeatPosition(1, 4, isMobile);
    const opp2 = getDeterministicSeatPosition(2, 4, isMobile);

    assert.ok(parseFloat(opp0.left as string) > 75, 'opp0 must be on right side');
    assert.equal(opp1.left, '50%', 'opp1 must be in top center');
    assert.ok(parseFloat(opp2.left as string) < 25, 'opp2 must be on left side');
  }
});

test('deriveSeatViewModels preserves server seat number, visual index, privacy state, and targets', () => {
  const boardSeats = [102, 103, 101, 104];
  const playerIds = [101, 102, 103, 104];
  const ownId = 101; // Server seat 3 in boardSeats [102 (1), 103 (2), 101 (3), 104 (4)]
  const boardPlayers: Record<number, BoardPlayer> = {
    101: { hp: 3, maxHp: 4, phase: 'Play' } as BoardPlayer,
    102: { hp: 4, maxHp: 4, phase: 'NotActive' } as BoardPlayer,
    103: { hp: 2, maxHp: 4, phase: 'NotActive' } as BoardPlayer,
    104: { hp: 1, maxHp: 4, phase: 'NotActive' } as BoardPlayer,
  };
  const targetItems = {
    '102': { id: 102, enabled: true, selected: false },
    '103': { id: 103, enabled: false, selected: false },
    '104': { id: 104, enabled: true, selected: true },
  };

  const { selfSeat, opponentSeats, allSeats } = deriveSeatViewModels({
    boardSeats,
    playerIds,
    ownId,
    boardPlayers,
    gameplayActive: true,
    targetItems,
    isMobile: true,
  });

  // Verify Self
  assert.ok(selfSeat);
  assert.equal(selfSeat.playerId, 101);
  assert.equal(selfSeat.serverSeatNumber, 3, 'Self must retain absolute server seat 3');
  assert.equal(selfSeat.visualIndex, 0, 'Self visual index must be 0');
  assert.equal(selfSeat.isSelf, true);
  assert.equal(selfSeat.isActive, true, 'Self phase is Play, so active');
  assert.equal(selfSeat.isPrivate, true, 'Self has privacy access to own unrevealed generals');

  // Verify Opponents
  assert.equal(opponentSeats.length, 3);
  // Clockwise relative order starting after ownId (101): [104, 102, 103]
  assert.equal(opponentSeats[0].playerId, 104);
  assert.equal(opponentSeats[0].serverSeatNumber, 4);
  assert.equal(opponentSeats[0].visualIndex, 1);
  assert.equal(opponentSeats[0].isSelf, false);
  assert.equal(opponentSeats[0].isPrivate, false, 'Opponents must have isPrivate=false to protect hidden data');
  assert.equal(opponentSeats[0].isTargetable, true);
  assert.equal(opponentSeats[0].isSelectedTarget, true);

  assert.equal(opponentSeats[1].playerId, 102);
  assert.equal(opponentSeats[1].serverSeatNumber, 1);
  assert.equal(opponentSeats[1].visualIndex, 2);
  assert.equal(opponentSeats[1].isTargetable, true);
  assert.equal(opponentSeats[1].isSelectedTarget, false);

  assert.equal(opponentSeats[2].playerId, 103);
  assert.equal(opponentSeats[2].serverSeatNumber, 2);
  assert.equal(opponentSeats[2].visualIndex, 3);
  assert.equal(opponentSeats[2].isTargetable, false);

  assert.equal(allSeats.length, 4);
});
