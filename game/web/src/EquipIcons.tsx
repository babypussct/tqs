export type EquipSlotType = 'treasure' | 'weapon' | 'armor' | 'defensive_ride' | 'offensive_ride';

export function EquipIcon({ slot, className = '' }: { slot: EquipSlotType; className?: string }) {
  switch (slot) {
    case 'treasure':
      return (
        <svg className={`sg-equip-icon sg-equip-treasure ${className}`} viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <circle cx="12" cy="7" r="4" />
          <path d="M12 11v8" />
          <path d="M9 16h6" />
          <circle cx="12" cy="20" r="1.5" fill="currentColor" />
        </svg>
      );
    case 'weapon':
      return (
        <svg className={`sg-equip-icon sg-equip-weapon ${className}`} viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="14.5 17.5 3 6 3 3 6 3 17.5 14.5" />
          <line x1="13" y1="19" x2="19" y2="13" />
          <line x1="16" y1="16" x2="20" y2="20" />
          <line x1="19" y1="21" x2="21" y2="19" />
        </svg>
      );
    case 'armor':
      return (
        <svg className={`sg-equip-icon sg-equip-armor ${className}`} viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
        </svg>
      );
    case 'defensive_ride':
      return (
        <svg className={`sg-equip-icon sg-equip-def-ride ${className}`} viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M4 18c0-3 2-6 5-7l3-6h4l-2 5 4 1c2 1 3 3 3 6" />
          <circle cx="17" cy="6" r="1.5" fill="currentColor" />
          <path d="M6 21v-3" />
          <path d="M18 21v-3" />
        </svg>
      );
    case 'offensive_ride':
      return (
        <svg className={`sg-equip-icon sg-equip-off-ride ${className}`} viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M4 18c0-3 2-6 5-7l3-6h4l-2 5 4 1c2 1 3 3 3 6" />
          <circle cx="17" cy="6" r="1.5" fill="currentColor" />
          <line x1="2" y1="12" x2="8" y2="12" />
          <polyline points="5 9 8 12 5 15" />
        </svg>
      );
  }
}

export function TargetCrosshairIcon({ className = '' }: { className?: string }) {
  return (
    <svg className={`sg-target-crosshair ${className}`} viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="9" />
      <line x1="12" y1="2" x2="12" y2="7" />
      <line x1="12" y1="17" x2="12" y2="22" />
      <line x1="2" y1="12" x2="7" y2="12" />
      <line x1="17" y1="12" x2="22" y2="12" />
      <circle cx="12" cy="12" r="2.5" fill="currentColor" />
    </svg>
  );
}

export function TimerClockIcon({ className = '' }: { className?: string }) {
  return (
    <svg className={`sg-timer-icon ${className}`} viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="10" />
      <polyline points="12 6 12 12 16 14" />
    </svg>
  );
}

/** Compact toolbar icon for delegating the current turn to the native BOT. */
export function ToolbarBotIcon({ className = '' }: { className?: string }) {
  return (
    <svg className={`sg-toolbar-icon sg-toolbar-bot-icon ${className}`} viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="4" y="6" width="16" height="13" rx="3" />
      <path d="M12 3v3M8 11h.01M16 11h.01M8.5 15h7" />
      <path d="M4 11H2M22 11h-2" />
    </svg>
  );
}

/** Compact toolbar icon for leaving the current room/match. */
export function ToolbarExitIcon({ className = '' }: { className?: string }) {
  return (
    <svg className={`sg-toolbar-icon sg-toolbar-exit-icon ${className}`} viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M14 4H6.5A2.5 2.5 0 0 0 4 6.5v11A2.5 2.5 0 0 0 6.5 20H14" />
      <path d="M11 12h10M17 8l4 4-4 4" />
    </svg>
  );
}
