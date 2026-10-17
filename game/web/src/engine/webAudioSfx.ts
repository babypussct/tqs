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
  | 'losehp'
  | 'draw'
  | 'fly'
  | 'chain'
  | 'weapon'
  | 'armor'
  | 'horse';

export class SoundManager {
  private ctx: AudioContext | null = null;
  private enabled = true;
  private useNativeAudio = true;
  private customAudioMap: Partial<Record<SfxName, string>> = {};

  constructor() {
    this.registerDefaultNativeAudio();
  }

  /**
   * Automatically maps authentic FreeKill upstream audio assets from public directory.
   */
  private registerDefaultNativeAudio() {
    this.registerCustomAudio('card_play', '/audio/system/fly1.mp3');
    this.registerCustomAudio('fly', '/audio/system/fly1.mp3');
    this.registerCustomAudio('draw', '/audio/system/draw.mp3');
    this.registerCustomAudio('chain', '/audio/system/chain.mp3');
    this.registerCustomAudio('slash', '/audio/system/normal_damage.mp3');
    this.registerCustomAudio('fire_slash', '/audio/system/fire_damage.mp3');
    this.registerCustomAudio('thunder_slash', '/audio/system/thunder_damage.mp3');
    this.registerCustomAudio('damage', '/audio/system/normal_damage.mp3');
    this.registerCustomAudio('fire_damage', '/audio/system/fire_damage.mp3');
    this.registerCustomAudio('thunder_damage', '/audio/system/thunder_damage.mp3');
    this.registerCustomAudio('losehp', '/audio/system/losehp.mp3');
    this.registerCustomAudio('analeptic', '/audio/system/wine1.mp3');
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

  /**
   * Plays native card voice lines (male/female) identical to upstream FreeKill.
   */
  public playCardVoice(cardName: string, gender: 'male' | 'female' = 'male'): boolean {
    if (!this.enabled || !this.useNativeAudio || typeof Audio === 'undefined') return false;
    try {
      const cleanName = cardName.trim().toLowerCase();
      const audio = new Audio(`/audio/card/${gender}/${cleanName}.mp3`);
      audio.play().catch(() => {
        // Fallback to male if female is missing, or silent if not found
        if (gender === 'female') {
          const fallbackAudio = new Audio(`/audio/card/male/${cleanName}.mp3`);
          fallbackAudio.play().catch(() => {});
        }
      });
      return true;
    } catch {
      return false;
    }
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
      : 'damage';

    if (this.useNativeAudio && typeof Audio !== 'undefined') {
      try {
        const suffix = damageNum > 1 ? '2' : '';
        const audio = new Audio(`/audio/system/${damageType}${suffix}.mp3`);
        audio.play().catch(() => {
          this.playSlashSound(damageType.includes('thunder') ? 'thunder' : damageType.includes('fire') ? 'fire' : 'normal');
        });
        return;
      } catch {
        // Fallback below
      }
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
    this.playSlashSound('normal');
  }

  public playEquipSound(subType: 'weapon' | 'armor' | 'horse') {
    if (this.tryPlayCustomAudio(subType)) return;
    this.playCardPlaySound();
  }

  public playLoseHpSound() {
    if (this.tryPlayCustomAudio('losehp')) return;
    this.playSlashSound('normal');
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
