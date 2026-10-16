import { useEffect, useRef, type KeyboardEvent, type ReactNode } from 'react';

const FOCUSABLE = [
  'button:not(:disabled)',
  'input:not(:disabled)',
  'select:not(:disabled)',
  'textarea:not(:disabled)',
  '[href]',
  '[tabindex]:not([tabindex="-1"])',
].join(',');

export interface RequestDialogProps {
  children: ReactNode;
  label: string;
  focusKey: string | number;
  className?: string;
  labelledBy?: string;
  canCancel?: boolean;
  onCancel?: () => void;
}

/**
 * Shared shell for server-owned request dialogs.
 *
 * Requests are modal from the player's point of view: the board underneath
 * must not keep receiving keyboard focus while Lua waits for one reply.  The
 * shell only manages focus and cancellation affordances; validation and reply
 * bytes remain in the existing adapter/connection layer.
 */
export default function RequestDialog({
  children, label, focusKey, className = '', labelledBy, canCancel = false, onCancel,
}: RequestDialogProps) {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const panel = ref.current;
    if (!panel) return;
    const frame = window.requestAnimationFrame(() => {
      const first = panel.querySelector<HTMLElement>(FOCUSABLE);
      (first ?? panel).focus({ preventScroll: true });
    });
    return () => window.cancelAnimationFrame(frame);
  }, [focusKey]);

  const handleKeyDown = (event: KeyboardEvent<HTMLElement>) => {
    if (event.key === 'Escape' && canCancel && onCancel) {
      event.preventDefault();
      event.stopPropagation();
      onCancel();
      return;
    }
    if (event.key !== 'Tab') return;

    const focusable = Array.from(panelElements(ref.current));
    if (!focusable.length) {
      event.preventDefault();
      return;
    }
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    const active = document.activeElement;
    if (event.shiftKey && active === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && active === last) {
      event.preventDefault();
      first.focus();
    }
  };

  return (
    <section
      ref={ref}
      className={className}
      role="dialog"
      aria-modal="true"
      aria-label={label}
      aria-labelledby={labelledBy}
      tabIndex={-1}
      onKeyDown={handleKeyDown}
    >
      <div role="region" aria-label={label}>
        {children}
      </div>
    </section>
  );
}

function panelElements(panel: HTMLElement | null): HTMLElement[] {
  if (!panel) return [];
  return Array.from(panel.querySelectorAll<HTMLElement>(FOCUSABLE));
}
