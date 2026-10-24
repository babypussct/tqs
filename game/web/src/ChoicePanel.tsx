import { useEffect, useState } from 'react';
import { useDisplayText } from './engine/displayText';
import type { RequestInfo } from './engine/connection';
import { validChoiceReply, type ChoicePrompt } from './engine/choiceSelection';
import RequestDialog from './RequestDialog';

export default function ChoicePanel({ request, prompt, busy, respond }: {
  request: RequestInfo; prompt: ChoicePrompt; busy: boolean; respond: (choices: string[]) => void;
}) {
  const text = useDisplayText();
  const [selected, setSelected] = useState<string[]>([]);
  // A replacement request can reuse its numeric requestId within one clock tick.
  // Reset against the parsed prompt, not only the parent component's key.
  useEffect(() => setSelected([]), [prompt]);
  const [now, setNow] = useState(Date.now);
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, []);
  const expired = request.expiresAt !== null && now >= request.expiresAt;
  const disabled = busy || expired;
  return <RequestDialog className="panel request-panel" label="Lựa chọn trong trận"
    focusKey={`${request.requestId}:${request.receivedAt}`} canCancel={prompt.cancelable && !disabled}
    request={request}
    onCancel={() => respond([])}>
    <span className="section-label">Yêu cầu trong trận</span>
    <h2>{prompt.skill ? text(prompt.skill) : 'Chọn phương án'}</h2>
    <p>{text(prompt.prompt) || `Chọn từ ${prompt.min} đến ${prompt.max} phương án.`}</p>
    <div className="gameplay-options">{prompt.allChoices.map((choice) => {
      const checked = selected.includes(choice);
      return <button key={choice} type="button" aria-pressed={checked}
        className={`gameplay-choice ${checked ? 'selected' : ''}`}
        disabled={disabled || !prompt.choices.includes(choice) ||
          (!prompt.single && !checked && selected.length >= prompt.max)} onClick={() => {
          if (prompt.single) respond([choice]);
          else setSelected(checked ? selected.filter((v) => v !== choice) : [...selected, choice]);
        }}>{text(choice)}</button>;
    })}</div>
    <div className="request-actions">
      {!prompt.single && <button type="button" className="button primary"
        disabled={disabled || selected.length < prompt.min || !validChoiceReply(prompt, selected)}
        onClick={() => respond(selected)}>Xác nhận lựa chọn</button>}
      {prompt.cancelable && <button type="button" className="button secondary"
        disabled={disabled} onClick={() => respond([])}>Bỏ qua lựa chọn</button>}
    </div>
    {expired && <p role="status">Yêu cầu đã hết thời gian.</p>}
  </RequestDialog>;
}
