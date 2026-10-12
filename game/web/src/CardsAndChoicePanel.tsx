import { useEffect, useState } from 'react';
import type { RequestInfo } from './engine/connection';
import type { CardsAndChoicePrompt } from './engine/cardsAndChoice';
import { useDisplayText } from './engine/displayText';

export default function CardsAndChoicePanel({ request, prompt, busy, view, respond }: {
  request: RequestInfo; prompt: CardsAndChoicePrompt; busy: boolean;
  view: (selected: string[]) => { selectable: string[]; choices: string[] };
  respond: (selected: string[], choice: string, cancel?: boolean) => void;
}) {
  const text = useDisplayText();
  const [selected, setSelected] = useState<string[]>([]);
  const [now, setNow] = useState(Date.now);
  useEffect(() => setSelected([]), [prompt]);
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, []);
  const expired = request.expiresAt !== null && Math.max(now, Date.now()) >= request.expiresAt;
  const viewing = prompt.max === 0;
  let rules = { selectable: [] as string[], choices: [] as string[] };
  let error = '';
  if (!expired) {
    try { rules = view(selected); }
    catch (e) { error = (e as Error).message; }
  }
  const disabled = busy || expired;
  const label = (card: CardsAndChoicePrompt['cards'][number]) => <>
    {text(card.name || 'Lá bài')}
    {card.number !== undefined && <small> {({ 1: '♠', 2: '♣', 3: '♥', 4: '♦' } as Record<string, string>)[String(card.suit)] || ''}{card.number}</small>}
  </>;
  return <section className="panel request-panel" aria-label="Xem bài và chọn phương án">
    <span className="section-label">{viewing ? 'Xem bài' : 'Chọn bài và phương án'}</span>
    <h2>{viewing ? 'Xem các lá bài' : 'Chọn bài theo yêu cầu'}</h2>
    <p>{text(prompt.title) || (viewing ? 'Xem bài, sau đó xác nhận để tiếp tục.' : `Chọn từ ${prompt.min} đến ${prompt.max} lá bài.`)}</p>
    <div className="gameplay-options" role="group" aria-label="Các lá bài được phép xem">
      {prompt.cards.map((card) => viewing
        ? <div className="gameplay-choice" key={card.token}>{label(card)}</div>
        : <button type="button" key={card.token} aria-pressed={selected.includes(card.token)}
          className={`gameplay-choice ${selected.includes(card.token) ? 'selected' : ''}`}
          disabled={disabled || !!error || (!selected.includes(card.token) &&
            (!rules.selectable.includes(card.token) || selected.length >= prompt.max))}
          onClick={() => setSelected(selected.includes(card.token)
            ? selected.filter((token) => token !== card.token) : [...selected, card.token])}>{label(card)}</button>)}
    </div>
    {!prompt.cards.length && <p>Không có lá bài để xem.</p>}
    <div className="request-actions">
      {prompt.choices.map((choice) => <button type="button" className="button primary" key={choice}
        disabled={disabled || !!error || !rules.choices.includes(choice)}
        onClick={() => respond(selected, choice)}>{text(choice)}</button>)}
      {prompt.cancelChoices.map((choice) => <button type="button" className="button secondary" key={choice}
        disabled={disabled} onClick={() => respond([], choice, true)}>{text(choice)}</button>)}
    </div>
    {expired && <p role="status">Yêu cầu đã hết thời gian.</p>}
    {error && <p role="alert">{error}</p>}
  </section>;
}
