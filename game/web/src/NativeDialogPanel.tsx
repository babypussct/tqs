import { useEffect, useState } from 'react';
import type { RequestInfo } from './engine/connection';
import type { NativeDialogPrompt } from './engine/nativeDialogs';
import { useDisplayText } from './engine/displayText';
import RequestDialog from './RequestDialog';
import { userFacingError } from './engine/connectionMessages';
import { CardSuitMark, DialogCardItem, formatRank, getSuitInfo } from './HandCardItem';
import { GeneralPortrait } from './GeneralChoiceCard';

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
  if (!expired) { try { ({ rows, feasible, selectedTokens, selectableTokens } = view()); } catch (e) { error = userFacingError(e, 'gameplay'); } }
  const disabled = busy || expired || !!error;
  const cardLabel = (token: string) => {
    const card = prompt.cards.find(c => c.token === token);
    if (!card) return 'Lá bài';
    const name = text(card.name || 'Lá bài');
    return <>{name} <CardSuitMark suit={card.suit} number={card.number} /></>;
  };
  const cardLabelText = (token: string) => {
    const card = prompt.cards.find(c => c.token === token);
    if (!card) return 'Lá bài';
    return `${text(card.name || 'Lá bài')}${card.number !== undefined ? ` ${getSuitInfo(card.suit).name} ${formatRank(card.number)}` : ''}`;
  };
  const chooseName = (token: string) => {
    chooseGeneral(token);
    if (prompt.autoConfirm) respond();
  };
  const performMove = (area: number, index: number) => {
    if (!selected || disabled) return;
    move(selected, area, index); select(null);
  };
  const cancelToken = prompt.kind === 'generalsAndChoice' ? prompt.cancelOptions?.[0] : undefined;
  const canCancel = !disabled && (prompt.kind === 'generalsAndChoice' ? Boolean(cancelToken) : prompt.cancelable);
  return <RequestDialog className="panel request-panel" label="Lựa chọn bài và sắp xếp"
    focusKey={`${request.requestId}:${request.receivedAt}`} canCancel={canCancel}
    request={request}
    onCancel={() => prompt.kind === 'generalsAndChoice'
      ? cancelToken && respond(cancelToken, true)
      : respond(undefined, true)}>
    <h2>{prompt.kind === 'arrange' ? 'Sắp xếp bài' : prompt.kind === 'ag' || prompt.kind === 'boardMove' ? 'Chọn một lá bài' : ['generalChoice', 'skills', 'generalsAndChoice', 'cardNames'].includes(prompt.kind) ? (prompt.kind === 'skills' ? 'Chọn kỹ năng' : prompt.kind === 'cardNames' ? 'Chọn tên bài' : 'Chọn tướng') : 'Xem tướng'}</h2>
    <p>{text(prompt.title)}</p>
    {prompt.kind === 'generals' ? <div className="gameplay-options">
      {prompt.cards.map(card => <div className="gameplay-choice sg-general-choice-token" key={card.token}>
        <GeneralPortrait name={card.name!} label={text(card.name!)} compact />
        <span>{text(card.name!)}</span>
      </div>)}
    </div> : rows.map((row, area) => <div key={area} role="group" aria-label={text(prompt.names[area] ?? '') || `Nhóm ${area + 1}`}>
      {prompt.kind === 'arrange' && <h3>{text(prompt.names[area] ?? '') || `Nhóm ${area + 1}`}</h3>}
      <div className="gameplay-options">
        {row.map((token, index) => {
          const card = prompt.cards.find(c => c.token === token);
          const isCardKind = ['ag', 'boardMove', 'arrange'].includes(prompt.kind);
          const isGeneralKind = ['generalChoice', 'generalsAndChoice'].includes(prompt.kind);

          return <div key={token} className="sg-native-dialog-item">
            {prompt.kind === 'arrange' && selected && <button type="button" className="button small-button" disabled={disabled}
              onClick={() => performMove(area, index)} aria-label={`Đặt trước ${cardLabelText(token)}`}>Đặt trước</button>}
            {isCardKind && card ? (
              <DialogCardItem
                name={card.name}
                suit={card.suit}
                number={card.number}
                hidden={card.hidden}
                selected={prompt.kind === 'arrange' ? selected === token : false}
                disabled={disabled}
                onClick={() => prompt.kind === 'ag' || prompt.kind === 'boardMove' ? respond(token) : select(selected === token ? null : token)}
              />
            ) : isGeneralKind ? (
              (() => {
                const generalCard = prompt.cards.find(c => c.token === token);
                const generalName = generalCard?.name || token;
                const generalTitle = text(generalName);
                return (
                  <button type="button" className={`gameplay-choice sg-general-choice-token ${selectedTokens?.includes(token) ? 'selected' : ''}`}
                    aria-label={generalTitle}
                    disabled={disabled || (!selectedTokens?.includes(token) && !selectableTokens?.includes(token))}
                    aria-pressed={selectedTokens?.includes(token)}
                    onClick={() => chooseName(token)}>
                    <span aria-hidden="true" style={{ display: 'inline-flex' }}>
                      <GeneralPortrait name={generalName} label={generalTitle} compact />
                    </span>
                    <span>{generalTitle}</span>
                  </button>
                );
              })()
            ) : (
              <button type="button" className="gameplay-choice"
                disabled={disabled || (['skills', 'cardNames'].includes(prompt.kind) && !selectedTokens?.includes(token) && !selectableTokens?.includes(token))}
                aria-pressed={['skills', 'cardNames'].includes(prompt.kind) ? selectedTokens?.includes(token) : selected === token}
                onClick={() => ['skills', 'cardNames'].includes(prompt.kind) ? chooseName(token) : select(selected === token ? null : token)}>
                {cardLabel(token)}
              </button>
            )}
          </div>;
        })}
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
  </RequestDialog>;
}
