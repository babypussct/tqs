/**
 * Web Audio SFX & Native Audio Engine for Tam Quốc Sát Web Client.
 *
 * Integrates authentic upstream FreeKill audio assets (damage impacts, card play voices,
 * equipment equip sounds, wine drinking SFX, iron chain sounds) while preserving
 * a 100% resilient Web Audio API synthesizer fallback mechanism when external audio
 * files are unavailable, muted, or running in headless testing environments.
 */

export type SfxName =
  | 'card_play'
  | 'slash'
  | 'fire_slash'
  | 'thunder_slash'
  | 'jink'
  | 'peach'
  | 'analeptic'
  | 'nullification'
  | 'damage'
  | 'fire_damage'
  | 'thunder_damage'
  | 'ice_damage'
  | 'losehp'
  | 'losemaxhp'
  | 'recast'
  | 'draw'
  | 'fly'
  | 'chain'
  | 'weapon'
  | 'armor'
  | 'horse';

export type CardAudioGender = 'male' | 'female';
export type CardEquipAudioType = 'weapon' | 'armor' | 'horse';

export interface CardAudioOptions {
  gender?: CardAudioGender;
  /** FreeKill package extensionName, when it is present in the public card model. */
  extension?: string;
  /** Original card name used by FreeKill when a view-as name has no voice asset. */
  trueName?: string;
  equipType?: CardEquipAudioType | null;
  onMissing?: () => void;
}

const SAFE_AUDIO_PART = /^[A-Za-z0-9_-]+$/;
const SOURCE_AUDIO_PACKAGES = ['hegemony', 'standard_cards', 'maneuvering', 'gamemode', 'mobile'] as const;

function safeAudioPart(value: string | undefined): string | null {
  const normalized = value?.trim().toLowerCase();
  return normalized && SAFE_AUDIO_PART.test(normalized) ? normalized : null;
}

/**
 * Resolve audio in the same order as FreeKill's usecard.lua:
 * package-local voice first, then the browser's standard voice catalogue and
 * the shipped package media. If a card has an expansion prefix (e.g. heg__nullification,
 * sa__drowning, rob__jink), the base trueName is also attempted as fallback.
 */
export function cardAudioUrlCandidates(cardName: string, options: CardAudioOptions = {}): string[] {
  const baseName = cardName.includes('__') ? cardName.split('__').slice(-1)[0] : undefined;
  const names = [...new Set([cardName, options.trueName, baseName]
    .map(safeAudioPart)
    .filter((name): name is string => !!name))];
  const extension = safeAudioPart(options.extension);
  const genders: CardAudioGender[] = options.gender === 'female' ? ['female', 'male'] : ['male'];
  const packages = [...new Set([
    extension,
    ...SOURCE_AUDIO_PACKAGES,
  ].filter((name): name is string => !!name))];
  const candidates: string[] = [];
  const add = (url: string) => {
    if (!candidates.includes(url)) candidates.push(url);
  };

  for (const name of names) {
    for (const gender of genders) {
      if (extension) add(`/packages/${extension}/audio/card/${gender}/${name}.mp3`);
      add(`/audio/card/${gender}/${name}.mp3`);
      for (const packageName of packages) {
        if (packageName === extension) continue;
        add(`/packages/${packageName}/audio/card/${gender}/${name}.mp3`);
      }
    }
    // Some upstream package effects use a non-gendered card sound (notably
    // standard_cards and maneuvering equipment skills).
    for (const packageName of packages) {
      add(`/packages/${packageName}/audio/card/${name}.mp3`);
    }
  }
  return candidates;
}

/**
 * Resolve audio URLs for equipment skill trigger sounds
 * (packages/standard_cards/audio/card/<equip>.mp3 or packages/maneuvering/audio/card/<equip>.mp3).
 */
export function equipSkillAudioUrlCandidates(equipName: string): string[] {
  const name = safeAudioPart(equipName);
  if (!name) return [];
  const baseName = name.includes('__') ? name.split('__').slice(-1)[0] : undefined;
  const names = [...new Set([name, baseName].filter((n): n is string => !!n))];
  const candidates: string[] = [];
  for (const n of names) {
    for (const pkg of ['standard_cards', 'maneuvering', 'hegemony', 'mobile', 'gamemode'] as const) {
      candidates.push(`/packages/${pkg}/audio/card/${n}.mp3`);
    }
    candidates.push(`/audio/card/${n}.mp3`);
  }
  return [...new Set(candidates)];
}

/**
 * Resolve sound paths emitted by server LogEvent (e.g. ./audio/system/recast,
 * ./audio/card/common/weapon, ./packages/hegemony/audio/card/male/known_both,
 * ./packages/standard_cards/audio/card/axe).
 * Models FreeKill SkinBank.getAudioByPath and usecard.lua.
 */
export function nativeSoundPathCandidates(rawPath: string): string[] {
  if (!rawPath || typeof rawPath !== 'string') return [];
  const trimmed = rawPath.trim();
  if (!trimmed || trimmed.includes('..')) return [];
  const normalized = trimmed.replace(/^\.?\//, '').replace(/\.mp3$/i, '');
  if (!/^[A-Za-z0-9_/-]+$/.test(normalized)) return [];

  const candidates: string[] = [];
  const add = (p: string) => {
    const url = p.startsWith('/') ? p : `/${p}`;
    const full = url.endsWith('.mp3') ? url : `${url}.mp3`;
    if (!candidates.includes(full)) candidates.push(full);
  };

  // 1. Direct path
  add(normalized);

  // 2. If path is packages/<pkg>/audio/card/<gender>/<cardName>
  const cardMatch = normalized.match(/^packages\/([A-Za-z0-9_-]+)\/audio\/card\/(male|female)\/([A-Za-z0-9_-]+)$/);
  if (cardMatch) {
    const [, pkg, gender, cardName] = cardMatch;
    add(`audio/card/${gender}/${cardName}`);
    for (const p of SOURCE_AUDIO_PACKAGES) {
      if (p !== pkg) add(`packages/${p}/audio/card/${gender}/${cardName}`);
    }
    if (cardName.includes('__')) {
      const baseName = cardName.split('__').slice(-1)[0];
      add(`packages/${pkg}/audio/card/${gender}/${baseName}`);
      add(`audio/card/${gender}/${baseName}`);
      for (const p of SOURCE_AUDIO_PACKAGES) {
        add(`packages/${p}/audio/card/${gender}/${baseName}`);
      }
    }
  }

  // 3. If path is packages/<pkg>/audio/card/<equipName>
  const equipMatch = normalized.match(/^packages\/([A-Za-z0-9_-]+)\/audio\/card\/([A-Za-z0-9_-]+)$/);
  if (equipMatch) {
    const [, pkg, equipName] = equipMatch;
    for (const p of SOURCE_AUDIO_PACKAGES) {
      if (p !== pkg) add(`packages/${p}/audio/card/${equipName}`);
    }
    add(`audio/card/${equipName}`);
    if (equipName.includes('__')) {
      const baseName = equipName.split('__').slice(-1)[0];
      add(`packages/${pkg}/audio/card/${baseName}`);
      for (const p of SOURCE_AUDIO_PACKAGES) {
        add(`packages/${p}/audio/card/${baseName}`);
      }
    }
  }

  // 4. If path is audio/system/<name>
  const systemMatch = normalized.match(/^audio\/system\/([A-Za-z0-9_-]+)$/);
  if (systemMatch) {
    const [, sysName] = systemMatch;
    if (sysName.startsWith('ice_damage')) {
      add('audio/system/normal_damage' + (sysName.endsWith('2') ? '2' : ''));
    }
    if (sysName === 'losemaxhp') {
      add('audio/system/losehp');
    }
  }

  return candidates;
}

export class SoundManager {
  private ctx: AudioContext | null = null;
  private enabled = true;
  private useNativeAudio = true;
  private customAudioMap: Partial<Record<SfxName, string>> = {};
  private recentSoundTimes = new Map<string, number>();

  constructor() {
    this.registerDefaultNativeAudio();
  }

  private shouldSuppressDuplicate(key: string, windowMs = 250): boolean {
    const now = Date.now();
    const last = this.recentSoundTimes.get(key) ?? 0;
    if (now - last < windowMs) return true;
    this.recentSoundTimes.set(key, now);
    if (this.recentSoundTimes.size > 100) {
      for (const [k, t] of this.recentSoundTimes) {
        if (now - t > 5000) this.recentSoundTimes.delete(k);
      }
    }
    return false;
  }

  /**
   * Automatically maps authentic FreeKill upstream audio assets from public directory.
   */
  private registerDefaultNativeAudio() {
    this.registerCustomAudio('chain', '/audio/system/chain.mp3');
    this.registerCustomAudio('slash', '/audio/system/normal_damage.mp3');
    this.registerCustomAudio('fire_slash', '/audio/system/fire_damage.mp3');
    this.registerCustomAudio('thunder_slash', '/audio/system/thunder_damage.mp3');
    this.registerCustomAudio('damage', '/audio/system/normal_damage.mp3');
    this.registerCustomAudio('fire_damage', '/audio/system/fire_damage.mp3');
    this.registerCustomAudio('thunder_damage', '/audio/system/thunder_damage.mp3');
    this.registerCustomAudio('ice_damage', '/audio/system/ice_damage.mp3');
    this.registerCustomAudio('losehp', '/audio/system/losehp.mp3');
    this.registerCustomAudio('losemaxhp', '/audio/system/losemaxhp.mp3');
    this.registerCustomAudio('recast', '/audio/system/recast.mp3');
    this.registerCustomAudio('weapon', '/audio/card/common/weapon.mp3');
    this.registerCustomAudio('armor', '/audio/card/common/armor.mp3');
    this.registerCustomAudio('horse', '/audio/card/common/horse.mp3');
  }

  private getContext(): AudioContext | null {
    if (!this.enabled || typeof window === 'undefined') return null;
    const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (!AudioCtx) return null;

    if (!this.ctx) {
      try {
        this.ctx = new AudioCtx();
      } catch {
        return null;
      }
    }

    if (this.ctx.state === 'suspended') {
      this.ctx.resume().catch(() => {});
    }

    return this.ctx;
  }

  public setEnabled(enable: boolean) {
    this.enabled = enable;
  }

  public isEnabled(): boolean {
    return this.enabled;
  }

  public setUseNativeAudio(useNative: boolean) {
    this.useNativeAudio = useNative;
  }

  public isUseNativeAudio(): boolean {
    return this.useNativeAudio;
  }

  /**
   * Registers a custom audio URL (MP3, WebM, OGG, WAV) for a specific sound effect.
   */
  public registerCustomAudio(name: SfxName, url: string) {
    this.customAudioMap[name] = url;
  }

  /**
   * Retrieves any registered custom audio URL for a sound effect.
   */
  public getCustomAudio(name: SfxName): string | undefined {
    return this.customAudioMap[name];
  }

  /**
   * Clears custom audio mappings.
   */
  public clearCustomAudio(name?: SfxName) {
    if (name) delete this.customAudioMap[name];
    else this.customAudioMap = {};
  }

  /**
   * Tries to play a registered custom audio file. Returns true if played, false if fallback is needed.
   */
  public tryPlayCustomAudio(name: SfxName): boolean {
    if (!this.enabled) return true;
    if (!this.useNativeAudio) return false;
    const url = this.customAudioMap[name];
    if (!url || typeof Audio === 'undefined') return false;
    try {
      const audio = new Audio(url);
      audio.play().catch(() => {});
      return true;
    } catch {
      return false;
    }
  }

  /** Try native URLs in order and invoke the resilient fallback only after all fail. */
  private playAudioCandidates(urls: string[], onMissing?: () => void): boolean {
    if (!this.enabled) return true;
    if (!this.useNativeAudio || typeof Audio === 'undefined') {
      onMissing?.();
      return false;
    }
    const candidates = [...new Set(urls.filter(Boolean))];
    if (!candidates.length) {
      onMissing?.();
      return false;
    }

    let index = 0;
    let settled = false;
    const tryNext = () => {
      if (settled) return;
      const url = candidates[index++];
      if (!url) {
        settled = true;
        onMissing?.();
        return;
      }
      let audio: HTMLAudioElement;
      try {
        audio = new Audio(url);
        const next = () => {
          if (settled) return;
          tryNext();
        };
        audio.onerror = next;
        const playResult = audio.play();
        if (playResult && typeof playResult.then === 'function') {
          playResult.then(() => {
            settled = true;
          }).catch(next);
        } else {
          // Test doubles and older WebViews may not return the play Promise.
          settled = true;
        }
      } catch {
        tryNext();
      }
    };
    tryNext();
    return true;
  }

  /**
   * Plays native card voice lines (male/female) identical to upstream FreeKill.
   */
  public playCardVoice(cardName: string, gender: CardAudioGender = 'male', options: Omit<CardAudioOptions, 'gender' | 'equipType'> = {}): boolean {
    return this.playAudioCandidates(
      cardAudioUrlCandidates(cardName, { ...options, gender }),
      options.onMissing,
    );
  }

  /** Play the source card-use sound: common equip subtype or package voice. */
  public playCardUseSound(cardName: string, options: CardAudioOptions = {}): boolean {
    // The server's PlaySound arrives separately from the card log. Share a key
    // across both paths so either arrival order produces one audible effect.
    const key = options.equipType ? `equip:${options.equipType}` : `card:${cardName}`;
    if (this.shouldSuppressDuplicate(key, 300)) return true;
    const fallback = options.onMissing ?? (() => this.playCardPlaySound());
    if (options.equipType) {
      return this.playAudioCandidates(
        [`/audio/card/common/${options.equipType}.mp3`],
        fallback,
      );
    }
    return this.playCardVoice(cardName, options.gender ?? 'male', {
      extension: options.extension,
      trueName: options.trueName,
      onMissing: fallback,
    });
  }

  /**
   * Plays a native sound by server path (e.g. ./audio/system/recast,
   * ./audio/card/common/weapon, ./packages/hegemony/audio/card/male/known_both,
   * ./packages/standard_cards/audio/card/axe).
   */
  public playNativeSoundPath(rawPath: string, onMissing?: () => void): boolean {
    const trimmed = (rawPath || '').trim().replace(/^\.?\//, '').replace(/\.mp3$/i, '');
    const cardMatch = trimmed.match(/audio\/card\/(male|female)\/([A-Za-z0-9_-]+)$/);
    if (cardMatch) {
      if (this.shouldSuppressDuplicate(`card:${cardMatch[2]}`, 300)) return true;
    }
    const equipMatch = trimmed.match(/audio\/card\/common\/(weapon|armor|horse)$/);
    if (equipMatch) {
      if (this.shouldSuppressDuplicate(`equip:${equipMatch[1]}`, 300)) return true;
    }
    const candidates = nativeSoundPathCandidates(rawPath);
    return this.playAudioCandidates(candidates, onMissing);
  }

  /**
   * Plays equipment skill trigger sound (e.g. eight_diagram, vine, silver_lion, blade, crossbow).
   */
  public playEquipSkillSound(equipName: string, onMissing?: () => void): boolean {
    const candidates = equipSkillAudioUrlCandidates(equipName);
    return this.playAudioCandidates(candidates, onMissing);
  }

  /**
   * Plays recast sound (iron_chain, known_both, fight_together, part_ways).
   */
  public playRecastSound(): boolean {
    if (this.tryPlayCustomAudio('recast')) return true;
    return this.playNativeSoundPath('/audio/system/recast.mp3', () => this.playCardPlaySound());
  }

  /**
   * Plays damage impact sound effect matching FreeKill's playDamageEffect in RoomBase.qml.
   */
  public playDamageSound(damageType = 'normal_damage', damageNum = 1) {
    if (!this.enabled) return;
    const sfxKey: SfxName = damageType.includes('thunder')
      ? 'thunder_damage'
      : damageType.includes('fire')
      ? 'fire_damage'
      : damageType.includes('ice')
      ? 'ice_damage'
      : 'damage';

    if (this.useNativeAudio && typeof Audio !== 'undefined') {
      const suffix = damageNum > 1 ? '2' : '';
      const candidates = [
        `/audio/system/${damageType}${suffix}.mp3`,
        ...(damageType.includes('ice') ? [`/audio/system/normal_damage${suffix}.mp3`] : []),
      ];
      this.playAudioCandidates(candidates, () => {
        if (this.tryPlayCustomAudio(sfxKey)) return;
        this.playSlashSound(damageType.includes('thunder') ? 'thunder' : damageType.includes('fire') ? 'fire' : 'normal');
      });
      return;
    }

    if (this.tryPlayCustomAudio(sfxKey)) return;
    this.playSlashSound(damageType.includes('thunder') ? 'thunder' : damageType.includes('fire') ? 'fire' : 'normal');
  }

  /** Tiếng lướt bài / rút bài nhẹ nhàng (Card swish/draw) */
  public playCardPlaySound() {
    if (this.tryPlayCustomAudio('card_play')) return;

    const ctx = this.getContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const filter = ctx.createBiquadFilter();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(450, now);
    osc.frequency.exponentialRampToValueAtTime(180, now + 0.12);

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(1200, now);

    gain.gain.setValueAtTime(0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.12);
  }

  public playFlySound() {
    if (this.tryPlayCustomAudio('fly')) return;
    this.playCardPlaySound();
  }

  public playDrawSound() {
    if (this.tryPlayCustomAudio('draw')) return;
    this.playCardPlaySound();
  }

  public playChainSound() {
    if (this.tryPlayCustomAudio('chain')) return;
    this.playNativeSoundPath('/audio/system/chain.mp3', () => this.playSlashSound('normal'));
  }

  public playEquipSound(subType: 'weapon' | 'armor' | 'horse') {
    if (this.shouldSuppressDuplicate(`equip:${subType}`, 300)) return;
    if (this.tryPlayCustomAudio(subType)) return;
    this.playAudioCandidates([`/audio/card/common/${subType}.mp3`], () => this.playCardPlaySound());
  }

  public playLoseHpSound() {
    if (this.tryPlayCustomAudio('losehp')) return;
    this.playNativeSoundPath('/audio/system/losehp.mp3', () => this.playSlashSound('normal'));
  }

  public playLoseMaxHpSound() {
    if (this.tryPlayCustomAudio('losemaxhp')) return;
    this.playNativeSoundPath('/audio/system/losemaxhp.mp3', () => this.playLoseHpSound());
  }

  /** Tiếng vung đao / chém trúng kim loại (Slash attack impact) */
  public playSlashSound(type: 'normal' | 'fire' | 'thunder' = 'normal') {
    const sfxKey: SfxName = type === 'fire' ? 'fire_slash' : type === 'thunder' ? 'thunder_slash' : 'slash';
    if (this.tryPlayCustomAudio(sfxKey)) return;

    const ctx = this.getContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    // Noise buffer for sword cut whoosh
    const bufferSize = ctx.sampleRate * 0.18;
    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }

    const noise = ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(type === 'fire' ? 1400 : type === 'thunder' ? 2400 : 1800, now);
    filter.Q.setValueAtTime(3, now);

    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.18);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    noise.start(now);

    // Sharp metallic blade strike tone
    const metalOsc = ctx.createOscillator();
    const metalGain = ctx.createGain();
    metalOsc.type = 'triangle';
    metalOsc.frequency.setValueAtTime(type === 'thunder' ? 620 : 880, now);
    metalOsc.frequency.exponentialRampToValueAtTime(220, now + 0.14);

    metalGain.gain.setValueAtTime(0.18, now);
    metalGain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);

    metalOsc.connect(metalGain);
    metalGain.connect(ctx.destination);

    metalOsc.start(now);
    metalOsc.stop(now + 0.14);
  }

  /** Tiếng né đòn đanh thép / khiên đỡ đòn (Jink / Dodge) */
  public playJinkSound(gender?: 'male' | 'female') {
    if (gender) {
      this.playCardVoice('jink', gender);
    }
    if (this.tryPlayCustomAudio('jink')) return;

    const ctx = this.getContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(520, now);
    osc.frequency.exponentialRampToValueAtTime(1180, now + 0.08);
    osc.frequency.exponentialRampToValueAtTime(740, now + 0.22);

    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.22);
  }

  /** Tiếng hoa đào hồi máu trong trẻo (Peach heal chime) */
  public playPeachSound(gender?: 'male' | 'female') {
    if (gender) {
      this.playCardVoice('peach', gender);
    }
    if (this.tryPlayCustomAudio('peach')) return;

    const ctx = this.getContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    const notes = [523.25, 659.25, 783.99, 1046.5]; // C5, E5, G5, C6 arpeggio
    notes.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      const startTime = now + idx * 0.06;

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, startTime);

      gain.gain.setValueAtTime(0.12, startTime);
      gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.28);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(startTime);
      osc.stop(startTime + 0.28);
    });
  }

  /** Tiếng rót rượu / say nộ khí (Analeptic drink) */
  public playAnalepticSound(gender?: 'male' | 'female') {
    if (gender) {
      this.playCardVoice('analeptic', gender);
    }
    if (this.tryPlayCustomAudio('analeptic')) return;

    const ctx = this.getContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(130, now);
    osc.frequency.linearRampToValueAtTime(180, now + 0.25);

    gain.gain.setValueAtTime(0.15, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);

    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(450, now);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.25);
  }

  /** Tiếng sấm sét rền vang (Thunder / Lightning) */
  public playThunderSound(gender?: 'male' | 'female') {
    if (gender) {
      this.playCardVoice('thunder__slash', gender);
    }
    if (this.tryPlayCustomAudio('thunder_slash')) return;

    const ctx = this.getContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    const bufferSize = ctx.sampleRate * 0.45;
    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }

    const noise = ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(800, now);
    filter.frequency.exponentialRampToValueAtTime(120, now + 0.45);

    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    noise.start(now);
  }

  /** Tiếng hóa giải Vô Giải Khả Kích (Nullification chime) */
  public playNullifySound(gender?: 'male' | 'female') {
    if (gender) {
      this.playCardVoice('nullification', gender);
    }
    if (this.tryPlayCustomAudio('nullification')) return;

    const ctx = this.getContext();
    if (!ctx) return;
    const now = ctx.currentTime;

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(880, now);
    osc.frequency.exponentialRampToValueAtTime(440, now + 0.2);

    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.2);
  }
}

export const soundManager = new SoundManager();
