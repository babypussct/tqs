/** Native FreeKill visual notification projection. */
export type NativeVfxPayload =
  | { kind: 'indicate'; fromPlayerId: number; toPlayerIds: number[] }
  | { kind: 'damage'; targetPlayerId: number; damageType: 'normal_damage' | 'fire_damage' | 'thunder_damage' | 'ice_damage'; damageNum: number }
  | { kind: 'invoke_skill'; playerId: number; skill: string; isUlt?: boolean }
  | { kind: 'sound'; path: string }
  | { kind: 'losehp'; targetPlayerId?: number }
  | { kind: 'losemaxhp'; targetPlayerId?: number };
export type NativeVfxEvent = NativeVfxPayload & { sequence: number; createdAt: number };

function validPlayerId(value: unknown): value is number {
  return typeof value === 'number' && Number.isSafeInteger(value) && value !== 0;
}

/** Mirrors RoomBase.qml doAnimate(Indicate/InvokeSkill) and logEvent(Damage/PlaySound/LoseHP/ChangeMaxHp). */
export function projectNativeVfx(command: string, data: unknown): NativeVfxPayload[] {
  if (!data || typeof data !== 'object' || Array.isArray(data)) return [];
  const event = data as Record<string, unknown>;
  if (command === 'Animate') {
    if (event.type === 'Indicate') {
      if (!validPlayerId(event.from) || !Array.isArray(event.to)) return [];
      const result: NativeVfxPayload[] = [];
      for (const row of event.to.slice(0, 32)) {
        if (!Array.isArray(row) || !validPlayerId(row[0])) continue;
        // Actor -> first player; then the first player -> subsequent players.
        result.push({ kind: 'indicate', fromPlayerId: event.from, toPlayerIds: [row[0]] });
        const remaining = row.slice(1, 33).filter(validPlayerId);
        if (remaining.length) result.push({ kind: 'indicate', fromPlayerId: row[0], toPlayerIds: remaining });
      }
      return result;
    }
    if (event.type === 'InvokeSkill' && validPlayerId(event.player) && typeof event.name === 'string') {
      return [{ kind: 'invoke_skill', playerId: event.player, skill: event.name, isUlt: false }];
    }
    if (event.type === 'InvokeUltSkill' && validPlayerId(event.player) && typeof event.name === 'string') {
      return [{ kind: 'invoke_skill', playerId: event.player, skill: event.name, isUlt: true }];
    }
  }
  if (command === 'LogEvent') {
    if (event.type === 'Damage' && validPlayerId(event.to)) {
      const damageType = event.damageType === 'fire_damage' || event.damageType === 'thunder_damage' || event.damageType === 'ice_damage'
        ? event.damageType : 'normal_damage';
      const damageNum = typeof event.damageNum === 'number' && Number.isFinite(event.damageNum)
        ? Math.max(1, Math.min(99, Math.trunc(event.damageNum))) : 1;
      return [{ kind: 'damage', targetPlayerId: event.to, damageType, damageNum }];
    }
    if (event.type === 'PlaySound' && typeof event.name === 'string' && event.name.length > 0 && event.name.length <= 160 && !event.name.includes('..')) {
      return [{ kind: 'sound', path: event.name }];
    }
    if (event.type === 'LoseHP') {
      return [{ kind: 'losehp', targetPlayerId: validPlayerId(event.to) ? event.to : undefined }];
    }
    if (event.type === 'ChangeMaxHp' && typeof event.num === 'number' && event.num < 0) {
      return [{ kind: 'losemaxhp', targetPlayerId: validPlayerId(event.to) ? event.to : undefined }];
    }
  }
  return [];
}
