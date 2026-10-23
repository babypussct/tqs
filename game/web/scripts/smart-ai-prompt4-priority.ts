import type { Prompt4AuditReport, Prompt4SkillRecord } from './smart-ai-prompt4-audit';

export type Prompt4PriorityRecord = {
  id: string;
  occurrenceCount: number;
  generalCount: number;
  poolFrequencyEstimate: number;
  poolFrequencyPer100Generals: number;
  observedMatchFrequency: number | null;
  strategicImpact: number;
  improvementOpportunity: number;
  priority: number;
  baselineHandlerKind: 'ai_handler' | 'default_handler' | 'no_decision_required' | 'missing';
  candidateHandlerKind: Prompt4SkillRecord['handlerKind'];
  status: 'group_1' | 'group_2' | 'group_3' | 'backlog';
  rationale: string;
};

export type Prompt4BacklogRecord = {
  order: number;
  id: string;
  occurrenceCount: number;
  generalCount: number;
  poolFrequencyEstimate: number;
  observedMatchFrequency: null;
  packages: string[];
  surfaces: string[];
  classes: string[];
  rationale: string;
};

/**
 * Evidence-backed qualitative scores for the Prompt 4 review.  The
 * scores are deliberately explicit and small (1..5); they are not a claim of
 * observed win-rate causality.  Match-level per-skill counts are unavailable
 * in the sanitized evidence, so every row uses the registered-pool estimate.
 */
export const PROMPT4_PRIORITY_EVIDENCE: Record<string, {
  strategicImpact: number;
  improvementOpportunity: number;
  baselineHandlerKind: Prompt4PriorityRecord['baselineHandlerKind'];
  status: Prompt4PriorityRecord['status'];
  rationale: string;
}> = {
  tianyi: {
    strategicImpact: 5, improvementOpportunity: 5, baselineHandlerKind: 'default_handler',
    status: 'group_1',
    rationale: 'Pindian win unlocks an extra/unlimited-distance/additional-target Slash; loss disables Slash for the turn.',
  },
  shangyi: {
    strategicImpact: 4, improvementOpportunity: 5, baselineHandlerKind: 'default_handler',
    status: 'group_1',
    rationale: 'Two pool occurrences; target and follow-up branch determine public information and optional enemy discard.',
  },
  tiaoxin: {
    strategicImpact: 4, improvementOpportunity: 5, baselineHandlerKind: 'default_handler',
    status: 'group_1',
    rationale: 'Two pool occurrences; target choice trades an enemy discard against a forced Slash response.',
  },
  'hs__zhiheng': {
    strategicImpact: 4, improvementOpportunity: 5, baselineHandlerKind: 'default_handler',
    status: 'group_1',
    rationale: 'Core hand-quality conversion; card count and discard quality determine whether the draw exchange is positive.',
  },
  'hs__kurou': {
    strategicImpact: 4, improvementOpportunity: 5, baselineHandlerKind: 'default_handler',
    status: 'group_1',
    rationale: 'Card advantage plus a Slash residue at the cost of HP; lethal/low-HP timing must be rejected.',
  },
  'hs__qiangxi': {
    strategicImpact: 4, improvementOpportunity: 5, baselineHandlerKind: 'default_handler',
    status: 'group_1',
    rationale: 'Direct damage with a choice between one HP and a weapon; faction-aware target and cost comparison are missing.',
  },
  'hs__longdan': {
    strategicImpact: 5, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_2',
    rationale: 'Frequent Slash/Jink conversion plus delayed damage/recovery choice; requires play and response-path parity.',
  },
  'hs__wusheng': {
    strategicImpact: 5, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_2',
    rationale: 'Flexible Slash conversion and Diamond distance bypass; target/resource policy must preserve response legality.',
  },
  'hs__luanji': {
    strategicImpact: 5, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_2',
    rationale: 'Two-card multi-target attack with per-suit phase cost; needs exhaustive suit/card and target evaluation.',
  },
  huoji: {
    strategicImpact: 4, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_2',
    rationale: 'Red-card Fire Attack conversion; response/target and card conservation policy need a dedicated view-as test.',
  },
  kanpo: {
    strategicImpact: 5, improvementOpportunity: 3, baselineHandlerKind: 'default_handler',
    status: 'group_2',
    rationale: 'Nullification timing is high impact but must use the existing contextual response evaluator, not a blind play strategy.',
  },
  jijiu: {
    strategicImpact: 5, improvementOpportunity: 3, baselineHandlerKind: 'default_handler',
    status: 'group_2',
    rationale: 'Peach response conversion can change survival; requires dying/response fixtures and no private-information shortcut.',
  },
  aocai: {
    strategicImpact: 4, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_3',
    rationale: 'Top-deck response choice preserves the lower-keep-value legal basic card and consumes only server-exposed candidates.',
  },
  beizhu: {
    strategicImpact: 4, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_3',
    rationale: 'Once-per-turn target conversion avoids low-HP activation, prefers the smallest hostile public hand, and discards the highest-value visible card in the no-Slash branch.',
  },
  choufa: {
    strategicImpact: 3, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_3',
    rationale: 'Hand-to-Slash conversion targets a friendly non-empty hand and reveals a card from the smallest visible category to maximize converted cards.',
  },
  cunsi: {
    strategicImpact: 4, improvementOpportunity: 3, baselineHandlerKind: 'default_handler',
    status: 'group_3',
    rationale: 'Limited general-sacrifice timing prefers a living same-faction ally who can use Yongjue and receive two cards, with self as a safe fallback.',
  },
  dimeng: {
    strategicImpact: 4, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_3',
    rationale: 'Two-target hand exchange selects an ally/enemy pair where the enemy has more public cards and pays the difference with the cheapest legal cards.',
  },
  duanfa: {
    strategicImpact: 3, improvementOpportunity: 4, baselineHandlerKind: 'default_handler',
    status: 'group_3',
    rationale: 'Black-card conversion evaluates low-keep-value prefixes under the phase cap and activates only for a positive simulated draw exchange.',
  },
};

type PriorityInput = Pick<Prompt4AuditReport, 'eligibleGeneralCount' | 'skills'>;

export function buildPrompt4Priority(report: PriorityInput): Prompt4PriorityRecord[] {
  const rows: Prompt4PriorityRecord[] = [];
  for (const skill of report.skills) {
    const evidence = PROMPT4_PRIORITY_EVIDENCE[skill.id];
    if (!evidence) continue;
    const frequencyPer100Generals = skill.poolFrequencyEstimate * 100;
    rows.push({
      id: skill.id,
      occurrenceCount: skill.occurrenceCount,
      generalCount: skill.generalCount,
      poolFrequencyEstimate: skill.poolFrequencyEstimate,
      poolFrequencyPer100Generals: frequencyPer100Generals,
      observedMatchFrequency: null,
      strategicImpact: evidence.strategicImpact,
      improvementOpportunity: evidence.improvementOpportunity,
      // Scale the frequency to occurrences per 100 eligible generals so the
      // shortlist is readable while preserving the requested product formula.
      priority: frequencyPer100Generals * evidence.strategicImpact * evidence.improvementOpportunity,
      baselineHandlerKind: evidence.baselineHandlerKind,
      candidateHandlerKind: skill.handlerKind,
      status: evidence.status,
      rationale: evidence.rationale,
    });
  }
  rows.sort((a, b) => b.priority - a.priority || b.occurrenceCount - a.occurrenceCount || a.id.localeCompare(b.id));
  return rows;
}

/**
 * Keep the unimplemented decision skills in an explicit, deterministic
 * backlog.  These rows deliberately do not receive invented impact or
 * opportunity scores: without skill-specific rule review and observed-match
 * evidence, the only defensible ordering signal is pool appearance, followed
 * by stable tie-breakers.  The shortlist above is the only place where the
 * qualitative Priority product is claimed.
 */
export function buildPrompt4Backlog(
  skills: readonly (Prompt4SkillRecord & { packages?: string[]; surfaces?: string[]; classes?: string[] })[],
): Prompt4BacklogRecord[] {
  const implemented = new Set(Object.keys(PROMPT4_PRIORITY_EVIDENCE));
  const rows = skills
    .filter((skill) => skill.handlerKind === 'default_handler' && !implemented.has(skill.id))
    .map((skill) => ({
      order: 0,
      id: skill.id,
      occurrenceCount: skill.occurrenceCount,
      generalCount: skill.generalCount,
      poolFrequencyEstimate: skill.poolFrequencyEstimate,
      observedMatchFrequency: null as null,
      packages: [...(skill.packages ?? [])].sort(),
      surfaces: [...(skill.surfaces ?? [])].sort(),
      classes: [...(skill.classes ?? [])].sort(),
      rationale: 'Backlog order uses pool general frequency, then reference count, then decision-surface presence and skill ID. Strategic impact, improvement opportunity and observed-match frequency remain unscored until a skill-specific rule review and opportunity telemetry exist.',
    }));
  rows.sort((a, b) => {
    if (a.generalCount !== b.generalCount) return b.generalCount - a.generalCount;
    if (a.occurrenceCount !== b.occurrenceCount) return b.occurrenceCount - a.occurrenceCount;
    const aDecision = a.surfaces.includes('decision') ? 0 : 1;
    const bDecision = b.surfaces.includes('decision') ? 0 : 1;
    return aDecision - bDecision || a.id.localeCompare(b.id);
  });
  rows.forEach((row, index) => { row.order = index + 1; });
  return rows;
}
