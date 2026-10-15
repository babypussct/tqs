import { useState, useEffect } from 'react';
import { useDisplayText } from './engine/displayText';
import { choices, objectValue } from './engine/gameplayInteraction';
import type { RequestInfo } from './engine/connection';
import type { GameplayItem, GameplayItemType, GameplayScene } from './store/gameplayState';
import type { RegularSkill } from './store/gameStore';
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

function ItemButton({ item, label, onClick, busy, card = false, className = '' }: {
  item: GameplayItem; label: string; onClick: () => void; busy: boolean; card?: boolean; className?: string;
}) {
  return <button className={`gameplay-choice ${card ? 'sg-card-button' : ''} ${className} ${item.selected ? 'selected' : ''}`} type="button"
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

type SortMode = 'default' | 'type' | 'suit' | 'number';

function sortHandcards(cards: GameplayItem[], mode: SortMode): GameplayItem[] {
  if (mode === 'default') return cards;
  const suitOrder: Record<number, number> = { 4: 1, 2: 2, 3: 3, 1: 4 }; // spade, heart, club, diamond
  const typeOrder: Record<string, number> = { basic: 1, trick: 2, delayed_trick: 3, equip: 4, unknown: 5 };

  return [...cards].sort((a, b) => {
    const dataA = objectValue(a.card) as CardData | null;
    const dataB = objectValue(b.card) as CardData | null;
    if (!dataA || !dataB) return 0;

    if (mode === 'type') {
      const catA = getCardCategory(dataA.name);
      const catB = getCardCategory(dataB.name);
      const orderA = typeOrder[catA.typeKey] ?? 5;
      const orderB = typeOrder[catB.typeKey] ?? 5;
      if (orderA !== orderB) return orderA - orderB;
      return (dataA.number || 0) - (dataB.number || 0);
    }
    if (mode === 'suit') {
      const orderA = suitOrder[dataA.suit ?? 0] ?? 99;
      const orderB = suitOrder[dataB.suit ?? 0] ?? 99;
      if (orderA !== orderB) return orderA - orderB;
      return (dataA.number || 0) - (dataB.number || 0);
    }
    if (mode === 'number') {
      const numA = dataA.number || 0;
      const numB = dataB.number || 0;
      if (numA !== numB) return numA - numB;
      return (suitOrder[dataA.suit ?? 0] ?? 99) - (suitOrder[dataB.suit ?? 0] ?? 99);
    }
    return 0;
  });
}

export function GameplayControls({ scene, request, regularSkills = [], busy, dispatch, direct, toggleTrust, trusting }: {
  scene: GameplayScene; request: RequestInfo; busy: boolean;
  regularSkills?: RegularSkill[];
  dispatch: GameplayDispatch; direct: GameplayDirect;
  toggleTrust?: () => void;
  trusting?: boolean;
}) {
  const text = useDisplayText();
  const cards = Object.values(scene.items.CardItem);
  const requestSkills = Object.values(scene.items.SkillButton);
  // Native SkillArea keeps every local dashboard skill visible, while the
  // request scene owns which of those skills is currently actionable. Merge
  // both sources so a passive/temporarily unavailable skill is still shown,
  // but only a Lua-created SkillButton can become enabled and clickable.
  const requestSkillByName = new Map(requestSkills.map((item) => [String(item.id), item]));
  const skills: GameplayItem[] = [
    ...regularSkills.map((skill) => requestSkillByName.get(skill.name) ?? {
      id: skill.name, enabled: false, selected: false,
    }),
    ...requestSkills.filter((item) => !regularSkills.some((skill) => skill.name === String(item.id))),
  ];
  const specials = Object.values(scene.items.SpecialSkills);
  const interactions = Object.values(scene.items.Interaction);
  const buttons = Object.values(scene.items.Button);
  const [inspectedCardId, setInspectedCardId] = useState<string | number | null>(null);
  const [sortMode, setSortMode] = useState<SortMode>('default');
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    if (!request.expiresAt || request.expiresAt <= Date.now()) return;
    const timer = setInterval(() => setNow(Date.now()), 250);
    return () => clearInterval(timer);
  }, [request.expiresAt]);

  const totalDuration = request.timeout > 0
    ? request.timeout * 1000
    : (request.expiresAt ? Math.max(1000, request.expiresAt - request.receivedAt) : 0);
  const remainingMs = request.expiresAt ? Math.max(0, request.expiresAt - now) : 0;
  const progressPercent = totalDuration > 0
    ? Math.min(100, Math.max(0, (remainingMs / totalDuration) * 100))
    : 100;

  const displayCards = sortHandcards(cards, sortMode);
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

  return (
    <section className="gameplay-controls sg-gameplay-controls" aria-label="Điều khiển lượt chơi">
      {/* 1. Floating Controls HUD (Prompt, ProgressBar, Action Buttons) */}
      <div className="sg-floating-controls-hud" aria-label="Bảng thao tác nổi">
        <div className="gameplay-control-heading sg-control-prompt-bar">
          <div className="sg-control-header-row sg-visually-hidden">
            <strong>Thao tác trong lượt</strong>
          </div>
          {request.timeout > 0 && request.expiresAt && (
            <div
              className="sg-timer-track"
              role="progressbar"
              aria-valuenow={Math.round(progressPercent)}
              aria-valuemin={0}
              aria-valuemax={100}
            >
              <div
                className={`sg-timer-fill${progressPercent < 30 ? ' urgent' : ''}`}
                style={{ width: `${progressPercent}%` }}
              />
            </div>
          )}
          {scene.prompt && (
            <p className="gameplay-prompt">
              {text(scene.prompt)}
              {request.timeout > 0 && remainingMs > 0 && (
                <span className="sg-timer-number" aria-label={`Còn ${Math.ceil(remainingMs / 1000)} giây`}>
                  &nbsp;(⏱ {Math.ceil(remainingMs / 1000)}s)
                </span>
              )}
            </p>
          )}
        </div>

        {disabledReasons.map((reason) => <p key={reason} className="notice" role="status">{text(reason)}</p>)}

        {selectedCard && (
          <SelectedCardSummary
            item={selectedCard}
            onInspect={() => setInspectedCardId(selectedCard.id)}
          />
        )}

        {/* Dải nút thao tác nổi (Action Row: OK, Cancel, End) */}
        {!!buttons.length && (
          <div className="gameplay-actions sg-action-bar" aria-label="Các nút hành động">
            {(['OK', 'Cancel', 'End'] as const).map((id) => {
              const item = scene.items.Button[id];
              if (!item) return null;
              const isOk = id === 'OK';
              const isCancel = id === 'Cancel';
              const btnClass = isOk
                ? 'primary sg-btn-ok'
                : isCancel
                ? 'secondary sg-btn-cancel'
                : 'secondary sg-btn-end';
              const label = isOk ? 'Xác nhận' : isCancel ? 'Hủy' : 'Kết thúc lượt';
              return (
                <button
                  key={id}
                  type="button"
                  className={`button ${btnClass}`}
                  disabled={waiting || !item.enabled}
                  onClick={() => dispatch('Button', id, 'click', null)}
                >
                  {label}
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* 2. Cột công cụ & sắp xếp bài bên tay trái */}
      <div className="sg-dashboard-left-tools" aria-label="Công cụ và sắp xếp bài">
        {toggleTrust && (
          <button
            type="button"
            className={`button small-button secondary sg-tool-btn${trusting ? ' active' : ''}`}
            onClick={toggleTrust}
            title={trusting ? 'Hủy BOT chơi hộ' : 'Bật BOT chơi hộ'}
          >
            {trusting ? 'Hủy ủy thác' : 'Ủy thác'}
          </button>
        )}
        <button
          type="button"
          className="button small-button secondary sg-tool-btn sg-sort-btn"
          onClick={() => {
            const nextMode: SortMode = sortMode === 'default' ? 'type' : sortMode === 'type' ? 'suit' : sortMode === 'number' ? 'default' : 'type';
            setSortMode(nextMode);
          }}
          title="Đổi cách sắp xếp bài trên tay (Mặc định / Loại / Chất / Điểm)"
        >
          Sắp xếp{sortMode !== 'default' ? `: ${sortMode === 'type' ? 'Loại' : sortMode === 'suit' ? 'Chất' : 'Điểm'}` : ''}
        </button>
      </div>

      {/* 3. Dải bài trên tay 130px chuẩn FreeKill HandcardArea */}
      {!!cards.length && (
        <div className="gameplay-card-section">
          <div className="gameplay-card-heading sg-visually-hidden">
            <div className="sg-hand-heading-left">
              <h3>Lá bài có thể chọn</h3>
              <span className="sg-hand-count" aria-label={`${cards.length} lá bài trên tay`}>
                {cards.length} lá
              </span>
            </div>
          </div>
          <div
            className={`gameplay-options gameplay-hand sg-hand-fan${cards.length > 4 ? ' sg-hand-overlap' : ''}`}
            data-card-count={cards.length}
            aria-label={`Bài trên tay, ${cards.length} lá. Cuộn ngang để xem thêm.`}
          >
            {displayCards.map((item, index) => (
              <HandCardItem
                key={item.id}
                item={item}
                index={index}
                totalCards={cards.length}
                busy={waiting}
                onClick={() => dispatch('CardItem', item.id, 'click', { selected: !item.selected })}
              />
            ))}
          </div>
          {cards.length > 6 && <p className="sg-hand-scroll-hint sg-visually-hidden">Vuốt hoặc cuộn ngang để xem toàn bộ bài trên tay</p>}
        </div>
      )}

      {/* 4. Khu vực Kỹ năng chuẩn FreeKill SkillArea (xếp tầng dọc cạnh ô ghế bản thân) */}
      {!!skills.length && (
        <div className="native-skill-dock" aria-label="Khu vực kỹ năng">
          <div className="native-skill-header sg-visually-hidden">
            <h3 className="native-skill-heading">Kỹ năng</h3>
            <span className="native-skill-hint">Chủ động / Trang bị</span>
          </div>
          <div className="gameplay-options native-skill-options">
            {skills.map((item) => (
              <ItemButton
                key={item.id}
                item={item}
                className="sg-skill-button"
                label={text(String(item.id))}
                busy={waiting}
                onClick={() =>
                  dispatch('SkillButton', item.id, 'click', {
                    selected: !item.selected,
                    autoTarget: false,
                  })
                }
              />
            ))}
          </div>
        </div>
      )}

      {/* 5. Tương tác đặc biệt SpecialSkills & InteractionPicker */}
      {specials.filter((item) => item.skills?.length).map((item) => (
        <div key={item.id}>
          <h3>Cách sử dụng lá bài</h3>
          <div className="gameplay-options">
            {item.skills?.map((skill) => (
              <button
                key={skill}
                type="button"
                className="gameplay-choice"
                disabled={waiting || !item.enabled}
                onClick={() => dispatch('SpecialSkills', item.id, 'click', skill)}
              >
                {skill === '_normal_use' ? 'Sử dụng thông thường' : text(skill)}
              </button>
            ))}
          </div>
        </div>
      ))}

      {interactions.map((item) => (
        <div key={item.id}>
          <h3>Tương tác kỹ năng{item.skill_name ? `: ${text(item.skill_name)}` : ''}</h3>
          <InteractionPicker item={item} dispatch={dispatch} direct={direct} busy={waiting} />
        </div>
      ))}

      {expired && <p className="notice error-notice">Yêu cầu đã hết thời gian.</p>}

      {inspectedCard && (
        <CardDetailSheet
          isOpen={true}
          onClose={() => setInspectedCardId(null)}
          displayName={inspectedText.displayName}
          category={inspectedCategory}
          suitInfo={inspectedSuit}
          rank={inspectedRank}
          description={inspectedText.description}
          card={inspectedData ?? undefined}
        />
      )}
    </section>
  );
}
