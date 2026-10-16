import { useEffect, useState } from 'react';
import type { RequestInfo } from './engine/connection';
import type { CardSelectionPrompt, PoxiView } from './engine/cardSelection';
import { useDisplayText } from './engine/displayText';
import RequestDialog from './RequestDialog';

export default function CardSelectionPanel({ request, prompt, busy, view, respond }: {
  request: RequestInfo; prompt: CardSelectionPrompt; busy: boolean;
  view: (selected: string[]) => PoxiView;
  respond: (selected: string[], cancel?: boolean) => void;
}) {
  const text = useDisplayText();
  const [selected, setSelected] = useState<string[]>([]);
  useEffect(() => setSelected([]), [prompt]);
  const [now, setNow] = useState(Date.now);
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, []);
  const expired = request.expiresAt !== null && Math.max(now, Date.now()) >= request.expiresAt;
  let rules: PoxiView = { prompt: prompt.title, selectable: [], feasible: false };
  let error = '';
  if (!expired) {
    try { rules = view(selected); }
    catch (e) { error = (e as Error).message; }
  }
  const disabled = busy || expired || !!error;
  return <RequestDialog className="panel request-panel" label="Chọn bài đối thủ"
    focusKey={`${request.requestId}:${request.receivedAt}`} canCancel={prompt.cancelable && !disabled}
    onCancel={() => respond([], true)}>
    <span className="section-label">Chọn bài</span>
    <h2>{prompt.mode === 'single' ? 'Chọn một lá bài' : 'Chọn các lá bài'}</h2>
    <p>{text(rules.prompt) || 'Chọn bài theo yêu cầu của kỹ năng.'}</p>
    <p className="muted">Bài úp được giữ kín. Chỉ bài công khai mới hiện tên.</p>
    {prompt.groups.map((group, i) => <div key={i} role="group" aria-label={text(group.name)}>
      <h3>{text(group.name)}</h3>
      <div className="gameplay-options">{group.cards.map((card) => {
        const checked = selected.includes(card.token);
        return <button key={card.token} type="button" aria-pressed={checked}
          className={`gameplay-choice ${checked ? 'selected' : ''}`}
          disabled={disabled || (!checked && !rules.selectable.includes(card.token))}
          onClick={() => {
            if (prompt.mode === 'single') respond([card.token]);
            else setSelected(checked ? selected.filter((t) => t !== card.token) : [...selected, card.token]);
          }}>
          {card.hidden ? 'Bài úp' : text(card.name || 'Lá bài công khai')}
          {!card.hidden && card.number !== undefined && <small> {({ 1: '♠', 2: '♣', 3: '♥', 4: '♦' } as Record<string, string>)[String(card.suit)] || ''}{card.number}</small>}
        </button>;
      })}</div>
    </div>)}
    <div className="request-actions">
      {prompt.mode === 'poxi' && <button className="button primary" type="button"
        disabled={disabled || !rules.feasible} onClick={() => respond(selected)}>Xác nhận chọn bài</button>}
      {prompt.cancelable && <button className="button secondary" type="button"
        disabled={disabled} onClick={() => respond([], true)}>Bỏ qua chọn bài</button>}
    </div>
    {expired && <p role="status">Yêu cầu đã hết thời gian.</p>}
    {error && <p role="alert">{error}</p>}
  </RequestDialog>;
}
