import { useDisplayText } from './engine/displayText';
import { useEffect, useState } from 'react';
import type { RequestInfo } from './engine/connection';
import type { SkillInvokePrompt } from './store/gameStore';
import RequestDialog from './RequestDialog';

/** The same Lua skill-request controls are used in the app and real-VM browser tests. */
export default function SkillInvokePanel({ busy, request, prompt, onRespond }: {
  busy: boolean;
  request: RequestInfo;
  prompt: SkillInvokePrompt | null;
  onRespond: (choice: 'OK' | 'Cancel') => void;
}) {
  const text = useDisplayText();
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    setNow(Date.now());
    if (request.expiresAt === null) return;
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, [request.requestId, request.expiresAt]);

  const seconds = request.expiresAt === null ? null : Math.max(0, Math.ceil((request.expiresAt - now) / 1000));
  const expired = seconds === 0;
  return (
    <RequestDialog className="panel request-panel" label="Yêu cầu kích hoạt kỹ năng"
      labelledBy="skill-request-title" focusKey={`${request.requestId}:${request.receivedAt}`}
      canCancel={Boolean(prompt && !expired && !busy)} onCancel={() => onRespond('Cancel')}>
      <span className="section-label">Yêu cầu trong trận</span>
      <div className="row-between">
        <h2 id="skill-request-title">Kích hoạt kỹ năng?</h2>
        <span className={`countdown ${expired ? 'expired' : ''}`} role="timer">
          {seconds === null ? 'Không giới hạn' : expired ? 'Hết giờ' : `${seconds}s`}
        </span>
      </div>
      {prompt ? <>
        <p className="skill-name">{text(prompt.skill)}</p>
        <p className="muted">{(() => {
          const promptText = prompt.prompt ? text(prompt.prompt) : '';
          return promptText && !promptText.startsWith('#') ? promptText : `Bạn có muốn kích hoạt ${text(prompt.skill)}?`;
        })()}</p>
      </> : <p className="muted">Đang tải thông tin kỹ năng từ Lua…</p>}
      <div className="request-actions">
        <button type="button" className="button primary" disabled={busy || expired || !prompt} onClick={() => onRespond('OK')}>Kích hoạt</button>
        <button type="button" className="button secondary" disabled={busy || expired || !prompt} onClick={() => onRespond('Cancel')}>Bỏ qua</button>
      </div>
    </RequestDialog>
  );
}
