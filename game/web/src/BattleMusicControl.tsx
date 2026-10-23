import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

// FreeKill Fk/Base/Config.qml: bgmFile = audio/system/bgm.mp3,
// bgmVolume = 50; LunarLtk/Pages/RoomBase.qml loops it for each room.
const BGM_PATH = '/audio/system/bgm.mp3';
const STORAGE_KEY = 'tqs.battleMusic.v1';
type Preferences = { enabled: boolean; volume: number };
type Playback = 'paused' | 'playing' | 'blocked' | 'unavailable';

function readPreferences(): Preferences {
  const defaults = { enabled: true, volume: 50 };
  if (typeof window === 'undefined') return defaults;
  try {
    const saved = JSON.parse(window.localStorage.getItem(STORAGE_KEY) ?? 'null') as Partial<Preferences> | null;
    return {
      enabled: typeof saved?.enabled === 'boolean' ? saved.enabled : defaults.enabled,
      volume: typeof saved?.volume === 'number' && Number.isFinite(saved.volume)
        ? Math.max(0, Math.min(100, Math.round(saved.volume))) : defaults.volume,
    };
  } catch {
    return defaults;
  }
}

export default function BattleMusicControl() {
  const [preferences, setPreferences] = useState(readPreferences);
  const [playback, setPlayback] = useState<Playback>('paused');
  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState<{ top: number; left: number } | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const popoverRef = useRef<HTMLDivElement>(null);
  const attemptRef = useRef(0);
  const enabledRef = useRef(preferences.enabled);
  enabledRef.current = preferences.enabled;

  const pause = useCallback(() => {
    attemptRef.current += 1;
    audioRef.current?.pause();
    setPlayback('paused');
  }, []);

  const play = useCallback(() => {
    const audio = audioRef.current;
    if (!audio || document.hidden) return;
    const attempt = ++attemptRef.current;
    try {
      Promise.resolve(audio.play()).then(() => {
        if (attempt !== attemptRef.current) return;
        if (audioRef.current !== audio || !enabledRef.current || document.hidden) {
          audio.pause();
          return;
        }
        setPlayback('playing');
      }).catch(() => {
        if (attempt === attemptRef.current) {
          setPlayback(audio.error ? 'unavailable' : audio.paused ? 'blocked' : 'playing');
        }
      });
    } catch {
      if (attempt === attemptRef.current) setPlayback('blocked');
    }
  }, []);

  useEffect(() => {
    if (typeof Audio === 'undefined') {
      setPlayback('unavailable');
      return;
    }
    let audio: HTMLAudioElement;
    try { audio = new Audio(BGM_PATH); } catch { setPlayback('unavailable'); return; }
    audio.loop = true;
    audio.preload = 'auto';
    audio.volume = preferences.volume / 100;
    audioRef.current = audio;
    const error = () => {
      attemptRef.current += 1;
      setPlayback('unavailable');
    };
    const visibility = () => {
      if (document.hidden) pause();
      else if (enabledRef.current) play();
    };
    audio.addEventListener('error', error);
    document.addEventListener('visibilitychange', visibility);
    if (enabledRef.current) play();
    return () => {
      attemptRef.current += 1;
      document.removeEventListener('visibilitychange', visibility);
      audio.removeEventListener('error', error);
      audio.pause();
      audioRef.current = null;
    };
    // One media element per mounted match; preferences are applied separately.
  }, [pause, play]);

  useEffect(() => {
    if (audioRef.current) audioRef.current.volume = preferences.volume / 100;
    try { window.localStorage.setItem(STORAGE_KEY, JSON.stringify(preferences)); } catch { /* optional storage */ }
  }, [preferences]);

  const toggle = () => {
    if (preferences.enabled && playback === 'playing') {
      enabledRef.current = false;
      setPreferences((old) => ({ ...old, enabled: false }));
      pause();
    } else {
      enabledRef.current = true;
      setPreferences((old) => ({ ...old, enabled: true }));
      // Call play() in the user's click handler: Safari/iOS requires a gesture.
      play();
    }
  };

  // The portrait game shell clips overflow to protect the cards. Position the
  // settings in a body portal so it remains reachable on short phones.
  useLayoutEffect(() => {
    if (!open) return;
    const updatePosition = () => {
      const anchor = buttonRef.current?.getBoundingClientRect();
      const popup = popoverRef.current;
      if (!anchor || !popup) return;
      const gap = 6;
      // Short landscape boards place gameplay confirmation near the right edge;
      // anchor music controls on the left so the action buttons remain tappable.
      const left = window.innerWidth > window.innerHeight && window.innerHeight <= 520
        ? 8 : Math.max(8, Math.min(anchor.right - popup.offsetWidth, window.innerWidth - popup.offsetWidth - 8));
      const top = anchor.bottom + gap + popup.offsetHeight <= window.innerHeight - 8
        ? anchor.bottom + gap : Math.max(8, anchor.top - popup.offsetHeight - gap);
      setPosition({ top, left });
    };
    updatePosition();
    window.addEventListener('resize', updatePosition);
    window.addEventListener('scroll', updatePosition, true);
    return () => {
      window.removeEventListener('resize', updatePosition);
      window.removeEventListener('scroll', updatePosition, true);
    };
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const dismiss = (event: PointerEvent) => {
      if (!buttonRef.current?.contains(event.target as Node) &&
          !popoverRef.current?.contains(event.target as Node)) setOpen(false);
    };
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setOpen(false);
        buttonRef.current?.focus();
      }
    };
    document.addEventListener('pointerdown', dismiss);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('pointerdown', dismiss);
      document.removeEventListener('keydown', onKey);
    };
  }, [open]);

  return (
    <div className="battle-music-settings">
      <button ref={buttonRef} type="button" className="button secondary sg-toolbar-action"
        aria-label="Cài đặt nhạc nền" aria-expanded={open} aria-controls="battle-music-popover"
        title="Nhạc nền trận đấu" data-playback={playback} data-enabled={preferences.enabled}
        onClick={() => { setPosition(null); setOpen((wasOpen) => !wasOpen); }}>
        <span className="sg-toolbar-action-icon" aria-hidden="true">♫</span>
        <span className="sg-toolbar-action-label">Nhạc</span>
      </button>
      {open && createPortal(
        <div id="battle-music-popover" ref={popoverRef} className="battle-music-popover"
          role="group" aria-label="Điều khiển nhạc nền trận đấu"
          style={{ top: position?.top ?? 0, left: position?.left ?? 0,
            visibility: position ? 'visible' : 'hidden' }}>
          <button type="button" className="button secondary" onClick={toggle}
            aria-pressed={preferences.enabled && playback === 'playing'}>
            {preferences.enabled && playback === 'playing' ? 'Tắt nhạc nền' : 'Phát nhạc nền'}
          </button>
          <label htmlFor="battle-music-volume">Âm lượng nhạc nền: {preferences.volume}%</label>
          <input id="battle-music-volume" type="range" min="0" max="100" step="5"
            value={preferences.volume} onChange={(event) => {
              const volume = Number(event.currentTarget.value);
              setPreferences((old) => ({ ...old, volume }));
            }} />
          {preferences.enabled && playback === 'blocked' &&
            <span className="battle-music-hint" role="status">Trình duyệt yêu cầu bấm Phát nhạc nền.</span>}
          {playback === 'unavailable' &&
            <span className="battle-music-hint" role="status">Không thể tải nhạc nền.</span>}
        </div>, document.body)}
    </div>
  );
}
