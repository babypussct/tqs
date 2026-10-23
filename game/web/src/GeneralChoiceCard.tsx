import { useEffect, useMemo, useState } from 'react';
import { generalArtCandidates } from './generalArt';
import type { InitialGeneralMetadata } from './engine/generalSelection';
import { plainText, useDisplayText } from './engine/displayText';
import { GeneralInfoTrigger } from './SkillInfo';

export type GeneralChoiceCardStatus =
  | 'normal'
  | 'main-selected'
  | 'deputy-selected'
  | 'invalid-for-deputy'
  | 'locked-pair-full'
  | 'expired'
  | 'busy';

const STATUS_LABEL: Record<GeneralChoiceCardStatus, string> = {
  normal: '',
  'main-selected': 'Chủ tướng',
  'deputy-selected': 'Phó tướng',
  'invalid-for-deputy': 'Không tương thích theo luật hiện tại',
  'locked-pair-full': 'Đã đủ cặp; bỏ chọn một vị trí trước',
  expired: 'Yêu cầu đã hết hạn',
  busy: 'Đang xử lý',
};

export function GeneralPortrait({
  name, label, className = '', compact = false,
}: { name: string; label: string; className?: string; compact?: boolean }) {
  const candidates = useMemo(() => generalArtCandidates({ name }), [name]);
  const [candidateIndex, setCandidateIndex] = useState(0);
  useEffect(() => setCandidateIndex(0), [name]);
  const source = candidates[candidateIndex];
  const safeLabel = plainText(label || name);
  if (!source) {
    return <span className={`sg-general-portrait sg-general-portrait-fallback${compact ? ' compact' : ''} ${className}`.trim()}
      aria-label={safeLabel} role="img"><span>{safeLabel.slice(0, 2)}</span></span>;
  }
  return <span className={`sg-general-portrait${compact ? ' compact' : ''} ${className}`.trim()}>
    <img src={source} alt={safeLabel} loading="lazy" onError={() => setCandidateIndex((index) => index + 1)} />
  </span>;
}

export interface GeneralChoiceCardProps {
  name: string;
  label: string;
  metadata?: InitialGeneralMetadata;
  status: GeneralChoiceCardStatus;
  position?: 'main' | 'deputy';
  onSelect: () => void;
  getSkills: () => string[];
}

export default function GeneralChoiceCard({
  name, label, metadata, status, position, onSelect, getSkills,
}: GeneralChoiceCardProps) {
  const text = useDisplayText();
  const disabled = status !== 'normal' && status !== 'main-selected' && status !== 'deputy-selected';
  const statusLabel = STATUS_LABEL[status];
  const hpAdjustments = [
    metadata?.mainMaxHp ? `Chủ ${metadata.mainMaxHp > 0 ? '+' : ''}${metadata.mainMaxHp}` : '',
    metadata?.deputyMaxHp ? `Phó ${metadata.deputyMaxHp > 0 ? '+' : ''}${metadata.deputyMaxHp}` : '',
  ].filter(Boolean);
  const actionLabel = position === 'main' ? `Bỏ chọn chủ tướng ${plainText(label)}`
    : position === 'deputy' ? `Bỏ chọn phó tướng ${plainText(label)}`
    : `Chọn ${plainText(label)}`;
  const fullLabel = statusLabel ? `${actionLabel}. ${statusLabel}.` : actionLabel;
  return <div className={`sg-general-choice-entry sg-general-choice-status-${status}`} data-general-id={name} data-general-status={status}>
    <button type="button" className={`general-choice${position ? ' selected' : ''}`}
      aria-label={fullLabel} aria-pressed={position !== undefined} disabled={disabled} onClick={onSelect}>
      <GeneralPortrait name={name} label={label} className="sg-general-choice-art" />
      <span className="sg-general-choice-copy">
        <strong>{plainText(label || text(name))}</strong>
        {metadata && <span className="sg-general-choice-meta">
          <span className={`sg-kingdom-label sg-kingdom-${safeClassPart(metadata.kingdom)}`}>{text(metadata.kingdom)}</span>
          {metadata.subkingdom && <span>{text(metadata.subkingdom)}</span>}
          {hpAdjustments.map((value) => <span key={value}>{value} HP</span>)}
          {metadata.companionWithOffer && <span className="sg-companion-badge" title="Có quan hệ Châu liên bích trong danh sách này">珠联</span>}
        </span>}
        {position && <span className="general-position">{position === 'main' ? 'Chủ tướng' : 'Phó tướng'}</span>}
        {statusLabel && !position && <span className="sg-general-choice-reason">{statusLabel}</span>}
      </span>
    </button>
    <GeneralInfoTrigger label={`Xem kỹ năng ${plainText(label || text(name))}`}
      getGroups={() => [{ general: name, role: position === 'main' ? 'Chủ tướng' : position === 'deputy' ? 'Phó tướng' : undefined, skills: getSkills() }]} />
  </div>;
}

function safeClassPart(value: string): string {
  return value.replace(/[^A-Za-z0-9_-]/g, '').slice(0, 40) || 'unknown';
}
