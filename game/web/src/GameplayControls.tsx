import { useState } from 'react';
import { useDisplayText } from './engine/displayText';
import { choices, objectValue } from './engine/gameplayInteraction';
import type { RequestInfo } from './engine/connection';
import type { GameplayItem, GameplayItemType, GameplayScene } from './store/gameplayState';
import {
  CardDetailSheet,
  formatRank,
  getCardCategory,
  getSuitInfo,
  HandCardItem,
  resolveCardText,
  SelectedCardSummary,
  type CardData,
} from './HandCardItem';

export type GameplayDispatch = (type: GameplayItemType, id: string | number,
  action: 'click' | 'update' | 'finish', data: unknown) => void;
export type GameplayDirect = (id: string | number, data: unknown) => void;

function ItemButton({ item, label, onClick, busy, card = false }: {
  item: GameplayItem; label: string; onClick: () => void; busy: boolean; card?: boolean;
}) {
  return <button className={`gameplay-choice ${card ? 'sg-card-button' : ''} ${item.selected ? 'selected' : ''}`} type="button"
    data-card-id={typeof item.id === 'number' ? item.id : undefined} aria-pressed={item.selected} disabled={busy || !item.enabled} onClick={onClick}>{label}</button>;
}

function list(value: unknown): unknown[] { return Array.isArray(value) ? value.slice(0, 256) : []; }

function InteractionPicker({ item, dispatch, direct, busy }: {
  item: GameplayItem; dispatch: GameplayDispatch; direct: GameplayDirect; busy: boolean;
}) {
  const text = useDisplayText();
  const spec = objectValue(item.spec);
  const [single, setSingle] = useState<string>(() => {
    const def = spec?.default;
    return typeof def === 'string' ? def : choices(spec?.choices ?? spec?.options)[0] ?? '';
  });
  const [multiple, setMultiple] = useState<string[]>(() =>
    Array.isArray(spec?.default) ? choices(spec.default) : []);
  const [number, setNumber] = useState<number>(() =>
    typeof spec?.default === 'number' ? spec.default : typeof spec?.from === 'number' ? spec.from : 0);
  const send = (action: 'update' | 'finish', data: unknown) => dispatch('Interaction', item.id, action, data);
  if (!spec) return <p className="muted">Thiếu mô tả tương tác từ Lua.</p>;
  const disabled = busy || !item.enabled;
  if (spec.type === 'combo' || spec.type === 'cardname') {
    const options = choices(spec.choices);
    return <label className="gameplay-input">{spec.type === 'cardname' ? 'Chọn tên lá bài' : 'Chọn phương án'}
      <select value={options.includes(single) ? single : options[0] ?? ''} disabled={disabled || !options.length}
        onChange={(e) => { setSingle(e.target.value); send('update', e.target.value); }}>
        {options.map((v) => <option key={v} value={v}>{text(v)}</option>)}
      </select>
    </label>;
  }
  if (spec.type === 'spin') {
    const min = typeof spec.from === 'number' ? spec.from : 0;
    const max = typeof spec.to === 'number' ? spec.to : min;
    return <label className="gameplay-input">Giá trị
      <input type="number" min={min} max={max} step={1} value={number} disabled={disabled}
        onChange={(e) => {
          const next = Number(e.target.value);
          setNumber(next);
          if (Number.isInteger(next) && next >= min && next <= max) send('update', next);
        }} />
    </label>;
  }
  if (spec.type === 'checkbox' || spec.type === 'optionbox') {
    const isOption = spec.type === 'optionbox';
    const options = choices(isOption ? spec.options : spec.choices);
    const directSend = isOption && spec.direct_send === true;
    const isSingle = isOption && spec.single !== false;
    const max = typeof spec.max_num === 'number' ? spec.max_num : 256;
    return <div className="gameplay-options" aria-label="Các phương án từ Lua">
      {options.map((value) => {
        const selected = isSingle ? single === value : multiple.includes(value);
        const enabled = !disabled && (selected || multiple.length < max || isSingle);
        return <button key={value} type="button" className={`gameplay-choice ${selected ? 'selected' : ''}`}
          aria-pressed={selected} disabled={!enabled} onClick={() => {
            if (directSend) {
              direct(item.id, value);
            } else if (isSingle) {
              setSingle(value);
              send('update', value);
            } else {
              const next = selected ? multiple.filter((x) => x !== value) : [...multiple, value];
              setMultiple(next);
              send('update', next);
            }
          }}>{text(value)}</button>;
      })}
      {spec.type === 'checkbox' && spec.cancelable === true &&
        <button type="button" className="button secondary small-button" disabled={disabled}
          onClick={() => { setMultiple([]); send('update', []); }}>Bỏ chọn</button>}
    </div>;
  }
  if (spec.type === 'expandItems') {
    const values: (string | number)[] = [
      ...list(spec.ids).filter((v): v is number => typeof v === 'number'),
      ...choices(spec.card_names),
    ];
    return <div className="gameplay-options">{values.map((value, index) =>
      <button type="button" key={`${typeof value}-${value}`} className="gameplay-choice"
        data-option-id={value} disabled={disabled} onClick={() => send('update', value)}>
        {typeof value === 'string' ? text(value) : `Lá bài ${index + 1}`}</button>)}</div>;
  }
  if (spec.type === 'ToBeDecided') {
    const refresh = objectValue(item.refresh_data);
    const option = objectValue(refresh?.optionBox);
    const enabledIds = Array.isArray(refresh?.enabled_ids) ? refresh.enabled_ids : null;
    const pendings = Array.isArray(refresh?.pendings) ? refresh.pendings : [];
    return <div className="gameplay-interaction-detail">
      {option && <div className="gameplay-options">
        {choices(option.options).map((value) => <button type="button" className="gameplay-choice"
          key={value} disabled={disabled} onClick={() => {
            if (option.direct_send === true) {
              direct(item.id, { option: value, autoTarget: false });
            } else send('update', { elemType: 'OptionBox', option: value, autoTarget: false });
          }}>{text(value)}</button>)}
        {option.cancelable === true && <button type="button" className="button secondary small-button"
          disabled={disabled} onClick={() => send('update', {
            elemType: 'OptionBox', option: 'Cancel', autoTarget: false,
          })}>Hủy phương án</button>}
      </div>}
      {list(refresh?.expandItems).length > 0 && <div className="gameplay-options">
        {list(refresh?.expandItems).map((raw, index) => {
          const row = objectValue(raw);
          if (!row || (typeof row.cid !== 'number' && typeof row.cid !== 'string') ||
            typeof row.name !== 'string') return null;
          const prop = objectValue(row.prop);
          return <button key={`${index}-${row.cid}`} type="button"
            className={`gameplay-choice ${pendings.includes(row.cid) ? 'selected' : ''}`}
            disabled={disabled || (enabledIds !== null && !enabledIds.includes(row.cid))}
            onClick={() => send('update', {
              elemType: 'ExpandItem', cid: row.cid, name: row.name, autoTarget: false,
            })}>{text(typeof prop?.name === 'string' ? prop.name : row.name)}</button>;
        })}
      </div>}
      {!option && !list(refresh?.expandItems).length && <p className="muted">Đang chờ lựa chọn do Lua cung cấp.</p>}
    </div>;
  }
  return <p className="notice" role="status">Tương tác “{String(spec.type ?? 'không rõ')}” yêu cầu giao diện đặc biệt chưa được hỗ trợ.</p>;
}

export function GameplayControls({ scene, request, busy, dispatch, direct }: {
  scene: GameplayScene; request: RequestInfo; busy: boolean;
  dispatch: GameplayDispatch; direct: GameplayDirect;
}) {
  const text = useDisplayText();
  const cards = Object.values(scene.items.CardItem);
  const skills = Object.values(scene.items.SkillButton);
  const specials = Object.values(scene.items.SpecialSkills);
  const interactions = Object.values(scene.items.Interaction);
  const buttons = Object.values(scene.items.Button);
  const [inspectedCardId, setInspectedCardId] = useState<string | number | null>(null);
  const selectedCard = cards.find((item) => item.selected) ?? null;
  const inspectedCard = inspectedCardId === null
    ? null
    : cards.find((item) => item.id === inspectedCardId && item.selected) ?? null;
  const inspectedData = objectValue(inspectedCard?.card) as CardData | null;
  const inspectedCategoryFromName = getCardCategory(inspectedData?.name);
  const inspectedCategory = inspectedCategoryFromName.typeKey === 'unknown'
    ? getCardCategory(inspectedData?.trueName)
    : inspectedCategoryFromName;
  const inspectedSuit = getSuitInfo(inspectedData?.suit);
  const inspectedRank = formatRank(inspectedData?.number);
  const inspectedText = resolveCardText(inspectedData ?? undefined, text);
  const disabledReasons = [...new Set(cards.filter((item) => !item.enabled && item.disabledReason)
    .map((item) => item.disabledReason!))];
  const expired = request.expiresAt !== null && Date.now() >= request.expiresAt;
  const waiting = busy || expired;
  return <section className="gameplay-controls sg-gameplay-controls" aria-label="Điều khiển lượt chơi">
    <div className="gameplay-control-heading">
      <strong>Thao tác trong lượt</strong>
    </div>
    {scene.prompt && <p className="gameplay-prompt">{text(scene.prompt)}</p>}
    {disabledReasons.map((reason) => <p key={reason} className="notice" role="status">{text(reason)}</p>)}
    {selectedCard && <SelectedCardSummary
      item={selectedCard}
      onInspect={() => setInspectedCardId(selectedCard.id)}
    />}
    {!!skills.length && <div><h3>Kỹ năng</h3><div className="gameplay-options">
      {skills.map((item) => <ItemButton key={item.id} item={item} label={text(String(item.id))} busy={waiting}
        onClick={() => dispatch('SkillButton', item.id, 'click', { selected: !item.selected, autoTarget: false })} />)}
    </div></div>}
    {!!cards.length && <div className="gameplay-card-section">
      <div className="gameplay-card-heading">
        <h3>Lá bài có thể chọn</h3>
        <span className="sg-hand-count" aria-label={`${cards.length} lá bài trên tay`}>
          {cards.length} lá
        </span>
      </div>
      <div
        className={`gameplay-options gameplay-hand sg-hand-fan${cards.length > 4 ? ' sg-hand-overlap' : ''}`}
        data-card-count={cards.length}
        aria-label={`Bài trên tay, ${cards.length} lá. Cuộn ngang để xem thêm.`}
      >
        {cards.map((item, index) => <HandCardItem key={item.id} item={item} index={index}
          totalCards={cards.length} busy={waiting}
          onClick={() => dispatch('CardItem', item.id, 'click', { selected: !item.selected })} />)}
      </div>
      {cards.length > 6 && <p className="sg-hand-scroll-hint">Vuốt hoặc cuộn ngang để xem toàn bộ bài trên tay</p>}
    </div>}
    {specials.filter((item) => item.skills?.length).map((item) => <div key={item.id}>
      <h3>Cách sử dụng lá bài</h3><div className="gameplay-options">
        {item.skills?.map((skill) => <button key={skill} type="button" className="gameplay-choice"
          disabled={waiting || !item.enabled} onClick={() => dispatch('SpecialSkills', item.id, 'click', skill)}>
          {skill === '_normal_use' ? 'Sử dụng thông thường' : text(skill)}</button>)}
      </div>
    </div>)}
    {interactions.map((item) => <div key={item.id}><h3>Tương tác kỹ năng{item.skill_name ? `: ${text(item.skill_name)}` : ''}</h3>
      <InteractionPicker item={item} dispatch={dispatch} direct={direct} busy={waiting} /></div>)}
    {!!buttons.length && <div className="gameplay-actions">
      {(['OK', 'Cancel', 'End'] as const).map((id) => {
        const item = scene.items.Button[id];
        return item && <button key={id} type="button"
          className={`button ${id === 'OK' ? 'primary' : 'secondary'}`}
          disabled={waiting || !item.enabled} onClick={() => dispatch('Button', id, 'click', null)}>
          {id === 'OK' ? 'Xác nhận' : id === 'Cancel' ? 'Hủy' : 'Kết thúc lượt'}</button>;
      })}
    </div>}
    {expired && <p className="notice error-notice">Yêu cầu đã hết thời gian.</p>}
    {inspectedCard && <CardDetailSheet
      isOpen={true}
      onClose={() => setInspectedCardId(null)}
      displayName={inspectedText.displayName}
      category={inspectedCategory}
      suitInfo={inspectedSuit}
      rank={inspectedRank}
      description={inspectedText.description}
      card={inspectedData ?? undefined}
    />}
  </section>;
}
