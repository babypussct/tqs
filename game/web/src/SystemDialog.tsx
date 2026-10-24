import { useEffect, useRef, type ReactNode } from 'react';
export default function SystemDialog({ title, close, children, forced = false }: {
  title: string; close?: () => void; children: ReactNode; forced?: boolean;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const previous = document.activeElement;
    const dialog = ref.current!;
    dialog.showModal();
    return () => { dialog.close(); if (previous instanceof HTMLElement && previous.isConnected) previous.focus(); };
  }, []);
  return <dialog ref={ref} className="tqs-system-dialog" aria-label={title} aria-modal="true"
    onCancel={(event) => { event.preventDefault(); if (!forced) close?.(); }}>
    <h2>{title}</h2>{children}
    {!forced && <button className="button ghost" onClick={close}>Đóng</button>}
  </dialog>;
}
