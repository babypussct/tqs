import { useEffect, useMemo, useState } from 'react';
import type { RequestInfo } from './engine/connection';
import { GameAdapter } from './engine/gameAdapter';
import type { InitialGeneralPrompt } from './engine/generalSelection';
import { plainText, useDisplayText } from './engine/displayText';

interface InitialGeneralPanelProps {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
  request: RequestInfo;
  prompt: InitialGeneralPrompt;
}

export default function InitialGeneralPanel({ adapter, run, busy, request, prompt }: InitialGeneralPanelProps) {
  const text = useDisplayText();
  const [chosen, setChosen] = useState<string[]>([]);
  const [kingdom, setKingdom] = useState('');
  const [warning, setWarning] = useState('');
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    setNow(Date.now());
    if (request.expiresAt === null) return;
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, [request.requestId, request.expiresAt]);

  const labels = useMemo(() => {
    try { return adapter.getGeneralLabels(prompt.generals); }
    catch { return prompt.generals; }
  }, [adapter, prompt]);
  const kingdoms = useMemo(() => {
    if (chosen.length !== 2) return [];
    try { return adapter.getInitialGeneralKingdoms(request.requestId, chosen[0], chosen[1]); }
    catch { return []; }
  }, [adapter, request.requestId, chosen]);
  const seconds = request.expiresAt === null ? null : Math.max(0, Math.ceil((request.expiresAt - now) / 1000));
  const expired = seconds === 0;
  const selectedKingdom = kingdoms.length === 1 ? kingdoms[0] : kingdom;
  const choose = (name: string) => {
    if (busy || expired) return;
    setWarning('');
    setKingdom('');
    if (chosen.includes(name)) {
      setChosen(chosen[0] === name ? [] : [chosen[0]]);
    } else if (chosen.length === 0 || chosen.length === 2) {
      setChosen([name]);
    } else {
      try {
        const valid = adapter.getInitialGeneralKingdoms(request.requestId, chosen[0], name);
        if (!valid.length) {
          setWarning('Phó tướng không tương thích với chủ tướng hoặc thế lực đã bật.');
          return;
        }
        setChosen([chosen[0], name]);
      } catch (error) {
        setWarning(error instanceof Error ? error.message : 'Không thể kiểm tra cặp tướng bằng Lua.');
      }
    }
  };
  const confirm = () => run(() => adapter.chooseInitialGenerals(request.requestId, chosen[0], chosen[1], selectedKingdom));

  return (
    <section className="panel request-panel" aria-labelledby="initial-general-title">
      <span className="section-label">Quốc Chiến · Chọn tướng</span>
      <div className="row-between">
        <h2 id="initial-general-title">Chọn chủ tướng và phó tướng</h2>
        <span className={`countdown ${expired ? 'expired' : ''}`} role="timer">
          {seconds === null ? 'Không giới hạn' : expired ? 'Hết giờ' : `${seconds}s`}
        </span>
      </div>
      <p className="muted">Chọn chủ tướng trước, sau đó chọn phó tướng tương thích. Nhấn lại tướng đã chọn để bỏ chọn.</p>
      <div className="chosen-generals" aria-live="polite">
        <div><span className="section-label">Chủ tướng</span><strong>{chosen[0] ? labels[prompt.generals.indexOf(chosen[0])] : 'Chưa chọn'}</strong></div>
        <div><span className="section-label">Phó tướng</span><strong>{chosen[1] ? labels[prompt.generals.indexOf(chosen[1])] : 'Chưa chọn'}</strong></div>
      </div>
      <div className="general-grid" role="group" aria-label="Danh sách võ tướng">
        {prompt.generals.map((name, index) => {
          const pos = chosen.indexOf(name);
          return <button key={`${name}-${index}`} type="button" className={`general-choice ${pos !== -1 ? 'selected' : ''}`}
            aria-pressed={pos !== -1} disabled={busy || expired} onClick={() => choose(name)}>
            <strong>{plainText(labels[index] || text(name))}</strong>
            {pos !== -1 && <span className="general-position">{pos === 0 ? 'Chủ tướng' : 'Phó tướng'}</span>}
          </button>;
        })}
      </div>
      {warning && <p className="notice" role="status">{warning}</p>}
      {chosen.length === 2 && kingdoms.length === 0 && <p className="notice error-notice">Cặp tướng này không có thế lực hợp lệ.</p>}
      {kingdoms.length > 1 && <fieldset className="kingdom-picker">
        <legend>Chọn thế lực</legend>
        {kingdoms.map((k) => <label key={k}><input type="radio" name={`kingdom-${request.requestId}`} value={k}
          checked={kingdom === k} disabled={busy || expired} onChange={() => setKingdom(k)} />{text(k)}</label>)}
      </fieldset>}
      {kingdoms.length === 1 && <p className="muted">Thế lực: <strong>{text(kingdoms[0])}</strong></p>}
      <div className="request-actions">
        <button type="button" className="button secondary" disabled={busy || expired || !chosen.length}
          onClick={() => { setChosen([]); setKingdom(''); setWarning(''); }}>Chọn lại</button>
        <button type="button" className="button primary" disabled={busy || expired || chosen.length !== 2 ||
          kingdoms.length === 0 || !kingdoms.includes(selectedKingdom)} onClick={confirm}>Xác nhận tướng</button>
      </div>
    </section>
  );
}
