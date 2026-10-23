import { useEffect, useMemo, useRef, useState } from 'react';
import type { RequestInfo } from './engine/connection';
import { GameAdapter } from './engine/gameAdapter';
import {
  createInitialGeneralChoiceState,
  isInitialGeneralReady,
  reduceInitialGeneralChoice,
  type InitialGeneralMetadata,
  type InitialGeneralPrompt,
  type InitialGeneralChoiceState,
} from './engine/generalSelection';
import { plainText, useDisplayText } from './engine/displayText';
import { userFacingError } from './engine/connectionMessages';
import RequestDialog from './RequestDialog';
import GeneralChoiceCard, { GeneralPortrait, type GeneralChoiceCardStatus } from './GeneralChoiceCard';

interface InitialGeneralPanelProps {
  adapter: GameAdapter;
  run: (action: () => void | Promise<void>) => void;
  busy: boolean;
  request: RequestInfo;
  prompt: InitialGeneralPrompt;
}

const KINGDOM_ASSETS = new Set(['wei', 'shu', 'wu', 'qun', 'god']);

export default function InitialGeneralPanel({ adapter, run, busy, request, prompt }: InitialGeneralPanelProps) {
  const text = useDisplayText();
  const [choice, setChoice] = useState<InitialGeneralChoiceState>(() =>
    createInitialGeneralChoiceState(request.requestId, prompt.generals));
  const [metadata, setMetadata] = useState<InitialGeneralMetadata[]>([]);
  const [labels, setLabels] = useState<string[]>(prompt.generals);
  const [metadataLoading, setMetadataLoading] = useState(true);
  const [metadataError, setMetadataError] = useState('');
  const [allowedDeputies, setAllowedDeputies] = useState<Record<string, string[]>>({});
  const [deputyEvaluating, setDeputyEvaluating] = useState(false);
  const [now, setNow] = useState(() => Date.now());
  const submitting = useRef(false);

  useEffect(() => {
    setNow(Date.now());
    if (request.expiresAt === null) return;
    const timer = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, [request.requestId, request.receivedAt, request.expiresAt]);

  useEffect(() => {
    let active = true;
    setMetadataLoading(true);
    setMetadataError('');
    try {
      const next = adapter.getInitialGeneralMetadata(request.requestId, prompt.generals);
      if (!active) return;
      if (next.length === prompt.generals.length) {
        setMetadata(next);
        setLabels(prompt.generals.map((name) => next.find((item) => item.name === name)?.label ?? name));
      } else {
        setMetadata([]);
        setMetadataError('Một phần thông tin tướng chưa nạp được; vẫn giữ nguyên luật chọn từ máy chủ.');
        try {
          const fallback = adapter.getGeneralLabels(prompt.generals);
          if (active && fallback.length === prompt.generals.length) setLabels(fallback);
        } catch { /* The raw offered IDs remain a safe display fallback. */ }
      }
    } catch (error) {
      if (!active) return;
      setMetadata([]);
      setMetadataError('Không nạp được thông tin tướng; luật chọn vẫn được kiểm tra bởi máy chủ.');
      try {
        const fallback = adapter.getGeneralLabels(prompt.generals);
        if (active && fallback.length === prompt.generals.length) setLabels(fallback);
      } catch { /* Keep the bounded server IDs as labels. */ }
      void error;
    } finally {
      if (active) setMetadataLoading(false);
    }
    return () => { active = false; };
  }, [adapter, request.requestId, prompt.generals]);

  const main = choice.chosen.length === 1 ? choice.chosen[0] : '';
  useEffect(() => {
    let active = true;
    if (!main || busy) {
      setAllowedDeputies({});
      setDeputyEvaluating(false);
      return;
    }
    setDeputyEvaluating(true);
    const next: Record<string, string[]> = {};
    for (const name of prompt.generals) {
      if (name === main) continue;
      try {
        next[name] = adapter.getInitialGeneralKingdoms(request.requestId, main, name);
      } catch {
        next[name] = [];
      }
    }
    if (active) {
      setAllowedDeputies(next);
      setDeputyEvaluating(false);
    }
    return () => { active = false; };
  }, [adapter, busy, main, prompt.generals, request.requestId]);

  const metadataByName = useMemo(() => new Map(metadata.map((item) => [item.name, item])), [metadata]);
  const labelByName = useMemo(() => new Map(prompt.generals.map((name, index) => [name, labels[index] || name])), [labels, prompt.generals]);
  const expiresAt = request.expiresAt;
  const expired = expiresAt !== null && now >= expiresAt;
  const seconds = expiresAt === null ? null : Math.max(0, Math.ceil((expiresAt - now) / 1000));
  const progress = expiresAt === null ? null : progressRatio(request.receivedAt, expiresAt, now);
  const selectedKingdom = choice.selectedKingdom;
  const confirmReady = isInitialGeneralReady(choice) && !expired && !busy && !submitting.current;

  const choose = (name: string) => {
    if (busy || expired || choice.phase === 'submitting' || submitting.current) return;
    if (choice.chosen.includes(name)) {
      setChoice((current) => reduceInitialGeneralChoice(current, { type: 'toggle-selected', name }));
      return;
    }
    if (choice.chosen.length === 0) {
      setChoice((current) => reduceInitialGeneralChoice(current, { type: 'select-main', name }));
      return;
    }
    if (choice.chosen.length !== 1) return; // A full pair locks every third card.
    try {
      // This call is cached in GameConnection by request/main/deputy and is
      // repeated here as a guard even if a stale UI event bypasses `disabled`.
      const kingdoms = adapter.getInitialGeneralKingdoms(request.requestId, choice.chosen[0], name);
      setChoice((current) => reduceInitialGeneralChoice(current, { type: 'select-deputy', name, kingdoms }));
    } catch (error) {
      setChoice((current) => ({ ...current, error: userFacingError(error, 'gameplay') }));
    }
  };

  const confirm = () => {
    if (!confirmReady) return;
    const [mainGeneral, deputyGeneral] = choice.chosen;
    const kingdom = selectedKingdom;
    submitting.current = true;
    setChoice((current) => reduceInitialGeneralChoice(current, { type: 'begin-submit' }));
    run(() => adapter.chooseInitialGenerals(request.requestId, mainGeneral, deputyGeneral, kingdom));
  };

  const reset = () => {
    if (busy || expired || submitting.current) return;
    setChoice((current) => reduceInitialGeneralChoice(current, { type: 'reset' }));
  };

  const cardStatus = (name: string): GeneralChoiceCardStatus => {
    if (expired) return 'expired';
    if (busy || choice.phase === 'submitting') return 'busy';
    const position = choice.chosen.indexOf(name);
    if (position === 0) return 'main-selected';
    if (position === 1) return 'deputy-selected';
    if (choice.chosen.length === 2) return 'locked-pair-full';
    if (choice.chosen.length === 1) {
      if (deputyEvaluating || !Object.prototype.hasOwnProperty.call(allowedDeputies, name)) return 'busy';
      if (!allowedDeputies[name]?.length) return 'invalid-for-deputy';
    }
    return 'normal';
  };

  return <RequestDialog className="panel request-panel sg-initial-general-dialog"
    label="Chọn chủ tướng và phó tướng" labelledBy="initial-general-title"
    focusKey={`${request.requestId}-${request.receivedAt}`}>
    <div className="sg-initial-general-dialog-body" data-testid="initial-general-dialog">
      <div className="sg-initial-general-header">
        <div>
          <span className="section-label">Quốc Chiến · Chọn tướng</span>
          <h2 id="initial-general-title">Chọn chủ tướng và phó tướng</h2>
        </div>
        <div className={`countdown${expired ? ' expired' : ''}`} role="timer" aria-live="polite">
          {seconds === null ? 'Không giới hạn' : expired ? 'Hết giờ · chờ máy chủ' : `${seconds}s`}
        </div>
      </div>
      <p className="muted sg-initial-general-help">Chọn chủ tướng trước, sau đó chọn phó tướng tương thích. Bấm lại vị trí đã chọn để bỏ; khi đủ cặp, tướng thứ ba sẽ bị khóa.</p>

      <div className="sg-initial-general-layout">
        <div className="sg-initial-general-offers">
          <div className="sg-initial-general-section-heading">
            <strong>Danh sách tướng được cấp</strong>
            <span>{prompt.generals.length} lựa chọn</span>
          </div>
          {metadataLoading && <p className="sg-inline-status" role="status">Đang nạp thông tin tướng…</p>}
          <div className="general-grid sg-initial-general-grid" role="group" aria-label="Danh sách võ tướng">
            {prompt.generals.map((name, index) => {
              const position = choice.chosen[0] === name ? 'main' : choice.chosen[1] === name ? 'deputy' : undefined;
              return <GeneralChoiceCard key={`${name}-${index}`} name={name}
                label={labelByName.get(name) ?? name} metadata={metadataByName.get(name)}
                position={position} status={cardStatus(name)} onSelect={() => choose(name)}
                getSkills={() => {
                  try { return adapter.getGeneralSkills(name); }
                  catch { return []; }
                }} />;
            })}
          </div>
        </div>

        <aside className="sg-initial-general-summary" aria-label="Tóm tắt lựa chọn">
          <div className="sg-initial-general-section-heading"><strong>Cặp đã chọn</strong><span>theo đúng thứ tự</span></div>
          <div className="sg-initial-general-slots chosen-generals">
            <SelectionSlot role="Chủ tướng" name={choice.chosen[0]} label={labelByName.get(choice.chosen[0]) ?? ''} />
            <SelectionSlot role="Phó tướng" name={choice.chosen[1]} label={labelByName.get(choice.chosen[1]) ?? ''} />
          </div>
          <KingdomPicker kingdoms={choice.kingdoms} selected={selectedKingdom} disabled={busy || expired || choice.phase === 'submitting'}
            text={text} onSelect={(kingdom) => setChoice((current) => reduceInitialGeneralChoice(current, { type: 'select-kingdom', kingdom }))} />
          {choice.chosen.length === 1 && <p className="sg-inline-status" role="status">
            {deputyEvaluating ? 'Đang kiểm tra cặp tướng theo luật Lua…' : 'Chọn một phó tướng còn sáng.'}
          </p>}
          {choice.error && <p className="notice error-notice sg-initial-general-error" role="alert">{choice.error}</p>}
          {metadataError && <p className="sg-inline-status sg-initial-general-metadata-warning" role="status">{metadataError}</p>}
        </aside>
      </div>

      <div className="sg-initial-general-footer">
        <div className="sg-initial-general-progress" aria-label="Thời gian còn lại">
          {progress !== null && <><progress max={1} value={progress} aria-label="Tiến trình thời gian" />
            <span>{expired ? 'Đã hết thời gian · máy chủ sẽ xử lý mặc định' : 'Máy chủ xử lý hết giờ'}</span></>}
          {progress === null && <span>Máy chủ xử lý hết giờ nếu không có xác nhận.</span>}
        </div>
        <div className="request-actions sg-initial-general-actions">
          <button type="button" className="button secondary" disabled={busy || expired || submitting.current || choice.chosen.length === 0} onClick={reset}>Chọn lại</button>
          <button type="button" className="button primary" disabled={!confirmReady || choice.kingdoms.length === 0} onClick={confirm}>Xác nhận tướng</button>
        </div>
      </div>
    </div>
  </RequestDialog>;
}

function SelectionSlot({ role, name, label }: { role: string; name?: string; label: string }) {
  return <div className={`sg-initial-general-slot${name ? ' filled' : ''}`} data-slot-role={role}>
    {name ? <GeneralPortrait name={name} label={label} compact /> : <span className="sg-initial-general-slot-placeholder">{role === 'Chủ tướng' ? '主' : '副'}</span>}
    <span><small>{role}</small><strong>{name ? plainText(label || name) : 'Chưa chọn'}</strong></span>
  </div>;
}

function KingdomPicker({
  kingdoms, selected, disabled, text, onSelect,
}: { kingdoms: string[]; selected: string; disabled: boolean; text: (value: string) => string; onSelect: (kingdom: string) => void }) {
  if (kingdoms.length === 0) return <p className="sg-initial-general-kingdom-empty">Chọn đủ một cặp để xác định thế lực.</p>;
  if (kingdoms.length === 1) return <div className="sg-initial-general-kingdom-single"><span>Thế lực</span><KingdomBadge kingdom={kingdoms[0]} label={text(kingdoms[0])} selected /></div>;
  return <fieldset className="kingdom-picker sg-initial-general-kingdom-picker">
    <legend>Chọn thế lực <span>(bắt buộc)</span></legend>
    <div className="sg-initial-general-kingdom-options">
      {kingdoms.map((kingdom) => <button key={kingdom} type="button" className="sg-kingdom-option" disabled={disabled}
        aria-label={`Chọn thế lực ${text(kingdom)}`} aria-pressed={selected === kingdom} onClick={() => onSelect(kingdom)}>
        <KingdomBadge kingdom={kingdom} label={text(kingdom)} selected={selected === kingdom} />
      </button>)}
    </div>
  </fieldset>;
}

function KingdomBadge({ kingdom, label, selected }: { kingdom: string; label: string; selected: boolean }) {
  const source = KINGDOM_ASSETS.has(kingdom) ? `/photo-assets/back/${kingdom}.png` : null;
  return <span className={`sg-kingdom-badge${selected ? ' selected' : ''}`} data-kingdom={kingdom}>
    {source ? <img src={source} alt="" aria-hidden="true" /> : <span className="sg-kingdom-text-mark">{label.slice(0, 1)}</span>}
    <strong>{plainText(label)}</strong>
  </span>;
}

function progressRatio(receivedAt: number, expiresAt: number, now: number): number {
  const total = expiresAt - receivedAt;
  if (total <= 0) return now >= expiresAt ? 1 : 0;
  return Math.max(0, Math.min(1, (now - receivedAt) / total));
}
