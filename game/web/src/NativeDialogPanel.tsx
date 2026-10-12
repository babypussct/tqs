import { useEffect, useState } from 'react';
import type { RequestInfo } from './engine/connection';
import type { NativeDialogPrompt } from './engine/nativeDialogs';
import { useDisplayText } from './engine/displayText';

export default function NativeDialogPanel({ request, prompt, busy, view, move, chooseGeneral, respond }: {
  request: RequestInfo; prompt: NativeDialogPrompt; busy: boolean;
  view: () => { rows: string[][]; feasible: boolean; selectedTokens?: string[]; selectableTokens?: string[] };
  chooseGeneral: (token: string) => void;
  move: (token: string, area: number, index: number) => void;
  respond: (token?: string, cancel?: boolean) => void;
}) {
  const text = useDisplayText();
  const [selected, select] = useState<string | null>(null);
  const [now, setNow] = useState(Date.now);
  useEffect(() => { select(null); }, [prompt]);
  useEffect(() => { const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer); }, []);
  const expired = request.expiresAt !== null && Math.max(now, Date.now()) >= request.expiresAt;
  let rows = prompt.rows; let feasible = false; let error = '';
  let selectedTokens: string[] | undefined; let selectableTokens: string[] | undefined;
  if (!expired) { try { ({ rows, feasible, selectedTokens, selectableTokens } = view()); } catch (e) { error = (e as Error).message; } }
  const disabled = busy || expired || !!error;
  const cardLabel = (token: string) => {
    const card = prompt.cards.find(c => c.token === token);
    if (!card) return 'Lá bài';
    return `${text(card.name || 'Lá bài')}${card.number !== undefined ? ` ${({ 1: '♠', 2: '♣', 3: '♥', 4: '♦' } as Record<string, string>)[String(card.suit)] || ''}${card.number}` : ''}`;
  };
  const chooseName = (token: string) => {
    chooseGeneral(token);
    if (prompt.autoConfirm) respond();
  };
  const performMove = (area: number, index: number) => {
    if (!selected || disabled) return;
    move(selected, area, index); select(null);
  };
  return <section className="panel request-panel" aria-label="Lựa chọn bài và sắp xếp">
    <h2>{prompt.kind === 'arrange' ? 'Sắp xếp bài' : prompt.kind === 'ag' || prompt.kind === 'boardMove' ? 'Chọn một lá bài' : ['generalChoice', 'skills', 'generalsAndChoice', 'cardNames'].includes(prompt.kind) ? (prompt.kind === 'skills' ? 'Chọn kỹ năng' : prompt.kind === 'cardNames' ? 'Chọn tên bài' : 'Chọn tướng') : 'Xem tướng'}</h2>
    <p>{text(prompt.title)}</p>
    {prompt.kind === 'generals' ? <div className="gameplay-options">
      {prompt.cards.map(card => <div className="gameplay-choice" key={card.token}>{text(card.name!)}</div>)}
    </div> : rows.map((row, area) => <div key={area} role="group" aria-label={text(prompt.names[area] ?? '') || `Nhóm ${area + 1}`}>
      {prompt.kind === 'arrange' && <h3>{text(prompt.names[area] ?? '') || `Nhóm ${area + 1}`}</h3>}
      <div className="gameplay-options">
        {row.map((token, index) => <div key={token}>
          {prompt.kind === 'arrange' && selected && <button type="button" className="button small-button" disabled={disabled}
            onClick={() => performMove(area, index)} aria-label={`Đặt trước ${cardLabel(token)}`}>Đặt trước</button>}
          <button type="button" className="gameplay-choice" disabled={disabled || (['generalChoice', 'skills', 'generalsAndChoice', 'cardNames'].includes(prompt.kind) && !selectedTokens?.includes(token) && !selectableTokens?.includes(token))} aria-pressed={['generalChoice', 'skills', 'generalsAndChoice', 'cardNames'].includes(prompt.kind) ? selectedTokens?.includes(token) : selected === token}
            onClick={() => prompt.kind === 'ag' || prompt.kind === 'boardMove' ? respond(token) : ['generalChoice', 'skills', 'generalsAndChoice', 'cardNames'].includes(prompt.kind) ? chooseName(token) : select(selected === token ? null : token)}>{cardLabel(token)}</button>
        </div>)}
        {prompt.kind === 'arrange' && <button type="button" className="button secondary" disabled={disabled || !selected}
          onClick={() => performMove(area, row.length)}>Đặt cuối nhóm {area + 1}</button>}
      </div>
    </div>)}
    {prompt.kind === 'arrange' && <p className="muted">Chọn một lá, rồi chọn vị trí đặt. Nhóm đầy sẽ đổi chỗ hai lá.</p>}
    <div className="request-actions">
      {prompt.kind === 'generalsAndChoice' && <>
        {prompt.okOptions?.map(choice => <button type="button" className="button primary" key={choice} disabled={disabled || !feasible} onClick={() => respond(choice)}>{choice === 'OK' ? 'Xác nhận' : text(choice)}</button>)}
        {prompt.cancelOptions?.map(choice => <button type="button" className="button secondary" key={choice} disabled={disabled} onClick={() => respond(choice, true)}>{text(choice)}</button>)}
      </>}
      {!['ag','boardMove','generalsAndChoice'].includes(prompt.kind) && <button type="button" className="button primary" disabled={disabled || !feasible}
        onClick={() => respond()}>Xác nhận</button>}
      {prompt.cancelable && prompt.kind !== 'generalsAndChoice' && <button type="button" className="button secondary" disabled={disabled} onClick={() => respond(undefined, true)}>Bỏ qua</button>}
    </div>
    {expired && <p role="status">Yêu cầu đã hết thời gian.</p>}
    {error && <p role="alert">{error}</p>}
  </section>;
}
