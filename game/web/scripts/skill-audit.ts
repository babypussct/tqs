/**
 * Skill inventory and release invariant for the pinned FreeKill package set.
 *
 * The baseline inventory deliberately audits General.other_skills, not
 * General:getSkillNameList(). The latter maps through Fk.skills and silently
 * drops an unresolved string, which is exactly the failure mode this gate is
 * intended to catch. The runtime contract audit additionally covers every
 * General skill collection exposed by the pinned FreeKill runtime.
 */
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LuaRuntime } from '../src/engine/luaRuntime';
import {
  BASELINE_PACKAGE_NAMES,
  loadUpstreamFiles,
  packageSpec,
  DECLARATION_REPAIRS,
  UPSTREAM_PACKAGE_NAMES,
  type UpstreamPackageSpec,
} from './upstream-packages';
import { VI_ADDITIONS } from '../src/engine/vietnamese';

const REPO_ROOT = fileURLToPath(new URL('../../../', import.meta.url));
const UPSTREAM_ROOT = path.join(REPO_ROOT, 'scratch/upstream');
const CJK = /[\u3400-\u9fff]/u;

type GeneralRecord = {
  name: string;
  trueName: string;
  package: string;
  hidden: boolean;
  totalHidden: boolean;
  refs: string[];
};

type TranslationRecord = { name: string; description: string };

type RuntimeSnapshot = {
  generals: GeneralRecord[];
  skillExists: Record<string, boolean>;
  skillCount: number;
  skeletonCount: number;
  translations: Record<string, TranslationRecord>;
  runtimeContracts: RuntimeContractAudit;
};

type RuntimeContractAudit = {
  generalCount: number;
  visibleGeneralCount: number;
  activeGeneralCount: number;
  activeVisibleGeneralCount: number;
  generalSkillReferenceCount: number;
  activeGeneralSkillReferenceCount: number;
  skillCount: number;
  skillClassCounts: Record<string, number>;
  skillSmokeCount: number;
  invalidSkillSmokeTotal: number;
  invalidSkillSmoke: string[];
  cardPackageCount: number;
  cardCount: number;
  derivedCardCount: number;
  cardSmokeCount: number;
  invalidCardSmokeTotal: number;
  invalidCardSmoke: string[];
  equipmentCount: number;
  equipmentSkillCount: number;
  equipmentSmokeCount: number;
  dynamicEquipmentCount: number;
  dynamicEquipmentSmokeCount: number;
  dynamicAttackRangeCount: number;
  dynamicAttackRangeSmokeCount: number;
  equipmentLifecycleSmokeCount: number;
  invalidEquipmentSmokeTotal: number;
  invalidEquipmentSmoke: string[];
  invalidDynamicEquipmentSmokeTotal: number;
  invalidDynamicEquipmentSmoke: string[];
  invalidDynamicAttackRangeSmokeTotal: number;
  invalidDynamicAttackRangeSmoke: string[];
  invalidEquipmentLifecycleSmokeTotal: number;
  invalidEquipmentLifecycleSmoke: string[];
  cardSkillReferenceCount: number;
  invalidGeneralSkillsTotal: number;
  invalidGeneralSkills: string[];
  activeInvalidGeneralSkillsTotal: number;
  activeInvalidGeneralSkills: string[];
  inactiveInvalidGeneralSkillsTotal: number;
  inactiveInvalidGeneralSkills: string[];
  invalidSkillsTotal: number;
  invalidSkills: string[];
  invalidCardsTotal: number;
  invalidCards: string[];
  invalidCardSkillsTotal: number;
  invalidCardSkills: string[];
};

type SourceLocation = {
  upstreamPackage: string;
  commit: string;
  file: string;
  line: number;
};

type ReferenceSummary = {
  generalCount: number;
  visibleGeneralCount: number;
  directReferenceOccurrences: number;
  directReferenceIds: number;
  missingOccurrences: number;
  missingIds: string[];
  byPackage: Record<string, {
    generals: number;
    directReferenceOccurrences: number;
    missingIds: string[];
  }>;
};

type MappingClassification =
  | 'resolved-in-baseline'
  | 'resolved-by-dependency'
  | 'declaration-repaired'
  | 'declaration-not-loaded'
  | 'declaration-variant-review'
  | 'implementation-missing';

type SkillMapping = {
  id: string;
  occurrences: number;
  declarations: Array<{
    general: string;
    trueName: string;
    package: string;
    visible: boolean;
  }>;
  classification: MappingClassification;
  declarationUpstream: Array<{ name: string; commit: string }>;
  exactImplementations: SourceLocation[];
  variantCandidates: SourceLocation[];
  runtimeResolved: boolean;
  effectiveRuntimeResolved: boolean;
  replacement?: string;
  reason: string;
};

type TranslationAudit = {
  referencedIds: number;
  translatedNames: number;
  translatedDescriptions: number;
  entries: Record<string, TranslationRecord>;
  rawNames: string[];
  cjkNames: string[];
  rawDescriptions: string[];
  cjkDescriptions: string[];
};

type AuditReport = {
  generatedAt: string;
  upstreamRoot: string;
  packages: UpstreamPackageSpec[];
  baseline: ReferenceSummary;
  dependencyComplete: ReferenceSummary;
  dependencyCompleteVisible: ReferenceSummary;
  baselineSkillCount: number;
  dependencyCompleteSkillCount: number;
  dependencyCompleteSkeletonCount: number;
  runtimeContracts: RuntimeContractAudit;
  mapping: SkillMapping[];
  translation: TranslationAudit;
  invariant: {
    baselineMissingIdsExpected: number;
    baselineMissingIdsActual: number;
    unresolvedVisibleIds: string[];
    pass: boolean;
  };
};

const LUA_AUDIT = String.raw`
local result = { generals = {}, skillExists = {}, skillCount = 0, skeletonCount = 0, translations = {},
  runtimeContracts = {
    generalCount = 0, visibleGeneralCount = 0, activeGeneralCount = 0, activeVisibleGeneralCount = 0,
    generalSkillReferenceCount = 0, activeGeneralSkillReferenceCount = 0,
    skillCount = 0, skillClassCounts = {}, skillSmokeCount = 0,
    invalidSkillSmokeTotal = 0, invalidSkillSmoke = {}, cardPackageCount = 0, cardCount = 0,
    derivedCardCount = 0, cardSmokeCount = 0, invalidCardSmokeTotal = 0, invalidCardSmoke = {},
    equipmentCount = 0, equipmentSkillCount = 0, equipmentSmokeCount = 0,
    invalidEquipmentSmokeTotal = 0, invalidEquipmentSmoke = {},
    dynamicEquipmentCount = 0, dynamicEquipmentSmokeCount = 0,
    invalidDynamicEquipmentSmokeTotal = 0, invalidDynamicEquipmentSmoke = {},
    dynamicAttackRangeCount = 0, dynamicAttackRangeSmokeCount = 0,
    invalidDynamicAttackRangeSmokeTotal = 0, invalidDynamicAttackRangeSmoke = {},
    equipmentLifecycleSmokeCount = 0,
    invalidEquipmentLifecycleSmokeTotal = 0, invalidEquipmentLifecycleSmoke = {},
    cardSkillReferenceCount = 0, invalidGeneralSkillsTotal = 0, invalidGeneralSkills = {},
    activeInvalidGeneralSkillsTotal = 0, activeInvalidGeneralSkills = {},
    inactiveInvalidGeneralSkillsTotal = 0, inactiveInvalidGeneralSkills = {},
    invalidSkillsTotal = 0, invalidSkills = {}, invalidCardsTotal = 0, invalidCards = {},
    invalidCardSkillsTotal = 0, invalidCardSkills = {},
  }
}

local contracts = result.runtimeContracts
local function sample(list, value)
  if #list < 32 then list[#list + 1] = value end
end

local modeDisabled = {}
for _, packageName in ipairs(Fk.game_mode_disabled["new_heg_mode"] or {}) do
  modeDisabled[packageName] = true
end

local function activeGeneral(general)
  local package = general and general.package
  return not package or not modeDisabled[package.name]
end

local function skillName(value)
  if type(value) == "string" then return value end
  if type(value) == "table" and type(value.name) == "string" then return value.name end
  return nil
end

for name, general in pairs(Fk.generals) do
  contracts.generalCount = contracts.generalCount + 1
  local isActive = activeGeneral(general)
  if isActive then contracts.activeGeneralCount = contracts.activeGeneralCount + 1 end
  if not general.hidden and not general.total_hidden then
    contracts.visibleGeneralCount = contracts.visibleGeneralCount + 1
    if isActive then contracts.activeVisibleGeneralCount = contracts.activeVisibleGeneralCount + 1 end
  end
  -- FreeKill stores skills in several General collections. other_skills
  -- contains the legacy string form, while newer declarations can populate
  -- skills/related_skills with Skill objects and
  -- related_other_skills with strings. all_skills is the UI aggregate.
  -- Deduplicate by name so the contract count describes each declared skill
  -- once without changing the historical direct-reference inventory below.
  local seenGeneralSkills = {}
  local function checkGeneralSkill(rawSkill)
    local ref = skillName(rawSkill)
    if ref and seenGeneralSkills[ref] then return end
    if ref then seenGeneralSkills[ref] = true end
    contracts.generalSkillReferenceCount = contracts.generalSkillReferenceCount + 1
    if isActive then contracts.activeGeneralSkillReferenceCount = contracts.activeGeneralSkillReferenceCount + 1 end
    if not ref or ref == "" or not Fk.skills[ref] then
      contracts.invalidGeneralSkillsTotal = contracts.invalidGeneralSkillsTotal + 1
      sample(contracts.invalidGeneralSkills, tostring(name) .. ":" .. tostring(ref or rawSkill))
      if isActive then
        contracts.activeInvalidGeneralSkillsTotal = contracts.activeInvalidGeneralSkillsTotal + 1
        sample(contracts.activeInvalidGeneralSkills, tostring(name) .. ":" .. tostring(ref or rawSkill))
      else
        contracts.inactiveInvalidGeneralSkillsTotal = contracts.inactiveInvalidGeneralSkillsTotal + 1
        sample(contracts.inactiveInvalidGeneralSkills, tostring(name) .. ":" .. tostring(ref or rawSkill))
      end
    end
  end
  for _, skill in ipairs(general.skills or {}) do checkGeneralSkill(skill) end
  for _, skill in ipairs(general.other_skills or {}) do checkGeneralSkill(skill) end
  for _, skill in ipairs(general.related_skills or {}) do checkGeneralSkill(skill) end
  for _, skill in ipairs(general.related_other_skills or {}) do checkGeneralSkill(skill) end
  for _, entry in ipairs(general.all_skills or {}) do
    checkGeneralSkill(type(entry) == "table" and entry[1] or entry)
  end
  if not __web_skill_audit_allowed or __web_skill_audit_allowed[name] then
    local refs = {}
    if type(general.other_skills) == "table" then
      for _, skill in ipairs(general.other_skills) do
        if type(skill) == "string" then refs[#refs + 1] = skill end
      end
    end
    result.generals[#result.generals + 1] = {
      name = name,
      trueName = general.trueName or "",
      package = general.package and general.package.name or "",
      hidden = general.hidden == true,
      totalHidden = general.total_hidden == true,
      refs = refs,
    }
  end
end

local baseSkillMethods = {
  "isEquipmentSkill", "isEffectable", "isPlayerSkill", "getTimes",
  "getDynamicDescription", "getSkeleton", "hasTag",
}
local requiredMethods = {
  -- ActiveSkill and ViewAsSkill inherit the ButtonSkill interaction surface;
  -- checking inherited defaults catches a broken class/metatable as well as a
  -- missing override in a package skill.
  ActiveSkill = {
    "canUse", "onUse", "cardFilter", "targetFilter", "feasible", "fixTargets",
    "update_interaction", "refresh_interaction",
  },
  ViewAsSkill = {
    "viewAs", "cardFilter", "targetFilter", "feasible", "fixTargets",
    "update_interaction", "refresh_interaction", "enabledAtPlay",
    "enabledAtResponse", "enabledAtNullification", "beforeUse", "afterUse",
    "afterResponse",
  },
  CardSkill = {
    "canUse", "cardFilter", "targetFilter", "modTargetFilter", "fixTargets",
    "getMinTargetNum", "getMaxTargetNum", "feasible", "getDistanceLimit",
    "getMaxUseTime", "withinDistanceLimit", "withinTimesLimit", "onUse",
    "onAction", "aboutToEffect", "onEffect", "onNullified", "preEffect",
  },
  -- event is data (the trigger key), not a callable method. The generated
  -- trigger skill must expose the executable trigger path instead.
  TriggerSkill = {
    "canRefresh", "refresh", "triggerable", "trigger", "doCost", "cost", "use",
    "canWake", "enableToWake", "triggerableTimes",
  },
  AttackRangeSkill = {
    "getCorrect", "getFixed", "getFinal", "withinAttackRange",
    "withoutAttackRange", "getVirtualWeaponAttackRange",
  },
  DistanceSkill = { "getCorrect", "getFixed" },
  FilterSkill = {
    "cardFilter", "viewAs", "equipSkillFilter", "handlyCardsFilter",
    "cardSkillFilter", "skillFilter", "cardPicFilter",
  },
  InvaliditySkill = { "getInvalidity", "getInvalidityAttackRange" },
  MaxCardsSkill = { "getFixed", "getCorrect", "excludeFrom" },
  ProhibitSkill = {
    "isProhibited", "prohibitUse", "prohibitResponse", "prohibitDiscard",
    "prohibitPindian",
  },
  TargetModSkill = {
    "bypassTimesCheck", "getResidueNum", "getFixedNum", "getFixedTargets",
    "bypassDistancesCheck", "getDistanceLimit", "getExtraTargetNum",
    "getCardTip", "getTargetTip", "isRemoved",
  },
  VisibilitySkill = { "cardVisible", "moveVisible", "roleVisible" },
  ["HegUtil.ArraySummonSkill"] = {
    "canUse", "onUse", "cardFilter", "targetFilter", "feasible", "fixTargets",
    "update_interaction", "refresh_interaction",
  },
  ["HegUtil.BigKingdomSkill"] = { "getFixed" },
}
for name, skill in pairs(Fk.skills) do
  contracts.skillCount = contracts.skillCount + 1
  result.skillCount = result.skillCount + 1
  local className = type(skill) == "table" and skill.class and skill.class.name or ""
  contracts.skillClassCounts[className] = (contracts.skillClassCounts[className] or 0) + 1
  if type(name) ~= "string" or name == "" or type(skill) ~= "table" or skill.name ~= name or className == "" then
    contracts.invalidSkillsTotal = contracts.invalidSkillsTotal + 1
    sample(contracts.invalidSkills, tostring(name))
  end
  local methods = {}
  for _, method in ipairs(baseSkillMethods) do methods[#methods + 1] = method end
  for _, method in ipairs(requiredMethods[className] or {}) do methods[#methods + 1] = method end
  for _, method in ipairs(methods) do
    if type(skill[method]) ~= "function" then
      contracts.invalidSkillsTotal = contracts.invalidSkillsTotal + 1
      sample(contracts.invalidSkills, tostring(name) .. "." .. method)
    end
  end
  local smokeChecks = {
    { name = "getSkeleton", invoke = function() return skill:getSkeleton() end,
      valid = function(value) return value == nil or type(value) == "table" end },
    { name = "hasTag", invoke = function() return skill:hasTag("__web_skill_audit_missing_tag__", false) end,
      valid = function(value) return type(value) == "boolean" end },
    { name = "isEquipmentSkill", invoke = function() return skill:isEquipmentSkill() end,
      valid = function(value) return type(value) == "boolean" end },
    { name = "isPlayerSkill", invoke = function() return skill:isPlayerSkill(nil, false) end,
      valid = function(value) return type(value) == "boolean" end },
  }
  if type(skill.times) ~= "function" then
    smokeChecks[#smokeChecks + 1] = {
      name = "getTimes", invoke = function() return skill:getTimes() end,
      valid = function(value) return type(value) == "number" end,
    }
  end
  for _, check in ipairs(smokeChecks) do
    contracts.skillSmokeCount = contracts.skillSmokeCount + 1
    local ok, value = pcall(check.invoke)
    if not ok or not check.valid(value) then
      contracts.invalidSkillSmokeTotal = contracts.invalidSkillSmokeTotal + 1
      sample(contracts.invalidSkillSmoke, tostring(name) .. "." .. check.name)
    end
  end
end

local cardRoom = Fk:currentRoom()
if cardRoom and type(cardRoom.status_skills) ~= "table" then cardRoom.status_skills = {} end
-- Dynamic equipment skills are the one card contract that needs an owner
-- object to execute. Use a deliberately inert Player-shaped probe: it
-- exposes only read-only, empty state and an unknown kingdom, so this audit
-- checks the callback and returned Skill objects without inventing a game
-- state or mutating a real player/room.
local dynamicEquipmentProbe = setmetatable({ id = 0, kingdom = "unknown" }, {
  __index = function(_, key)
    if key == "getTableMark" then return function() return {} end end
    if key == "getMark" then return function() return 0 end end
    if key == "hasSkill" then return function() return false end end
    if key == "getCardIds" or key == "getPile" or key == "getEquipments" then
      return function() return {} end
    end
    return function() return nil end
  end,
})
-- Lifecycle callbacks receive a Room and ServerPlayer in production. Keep
-- both as inert probes so custom onInstall/onUninstall implementations are
-- actually executed without mutating a real room/player or inventing rules.
local equipmentLifecycleRoomProbe = setmetatable({ players = {}, alive_players = {}, status_skills = {} }, {
  __index = function() return function() end end,
})
local equipmentLifecyclePlayerProbe = dynamicEquipmentProbe
for _, package in pairs(Fk.packages) do
  local packageCardCount = 0
  if type(package.cards) == "table" then
    for _, card in ipairs(package.cards) do
      packageCardCount = packageCardCount + 1
      if card.is_derived then contracts.derivedCardCount = contracts.derivedCardCount + 1
      else contracts.cardCount = contracts.cardCount + 1 end
      if type(card) ~= "table" or type(card.name) ~= "string" or card.name == "" or
          type(card.trueName) ~= "string" or card.trueName == "" or card.package ~= package or
          not card.class or type(card.class.name) ~= "string" or card.class.name == "" or
          type(card.type) ~= "number" then
        contracts.invalidCardsTotal = contracts.invalidCardsTotal + 1
        sample(contracts.invalidCards, tostring(card and card.name or "<nil>"))
      end
      if type(card) == "table" then
        local cardMethods = {
          "clone", "getSkill", "getFixedTargets", "getAvailableTargets",
          "getDefaultTarget", "getDynamicDescription", "getDynamicName",
        }
        for _, method in ipairs(cardMethods) do
          if type(card[method]) ~= "function" then
            contracts.invalidCardsTotal = contracts.invalidCardsTotal + 1
            sample(contracts.invalidCards, tostring(card.name) .. "." .. method)
          end
        end
        local cloneOk, cloned = pcall(function() return card:clone() end)
        if not cloneOk or type(cloned) ~= "table" or cloned.name ~= card.name then
          contracts.invalidCardsTotal = contracts.invalidCardsTotal + 1
          sample(contracts.invalidCards, tostring(card.name) .. ".clone()")
        end
        contracts.cardSmokeCount = contracts.cardSmokeCount + 1
        local skillOk, resolvedSkill = pcall(function() return card:getSkill(nil) end)
        local resolvedSkillName = skillName(resolvedSkill)
        if not skillOk or not resolvedSkillName or not Fk.skills[resolvedSkillName] then
          contracts.invalidCardSmokeTotal = contracts.invalidCardSmokeTotal + 1
          sample(contracts.invalidCardSmoke, tostring(card.name) .. ".getSkill()")
        end
        contracts.cardSmokeCount = contracts.cardSmokeCount + 1
        local nameOk, dynamicName = pcall(function() return card:getDynamicName(nil) end)
        if not nameOk or type(dynamicName) ~= "string" or dynamicName == "" then
          contracts.invalidCardSmokeTotal = contracts.invalidCardSmokeTotal + 1
          sample(contracts.invalidCardSmoke, tostring(card.name) .. ".getDynamicName()")
        end
        if card.dynamicDesc == nil then
          contracts.cardSmokeCount = contracts.cardSmokeCount + 1
          local descriptionOk, description = pcall(function() return card:getDynamicDescription(nil) end)
          if not descriptionOk or type(description) ~= "string" or description == "" then
            contracts.invalidCardSmokeTotal = contracts.invalidCardSmokeTotal + 1
            sample(contracts.invalidCardSmoke, tostring(card.name) .. ".getDynamicDescription()")
          end
        end
      end
      if card.type == Card.TypeEquip then
        contracts.equipmentCount = contracts.equipmentCount + 1
        local equipmentMethods = { "onInstall", "onUninstall", "getEquipSkills" }
        for _, method in ipairs(equipmentMethods) do
          if type(card[method]) ~= "function" then
            contracts.invalidCardsTotal = contracts.invalidCardsTotal + 1
            sample(contracts.invalidCards, tostring(card.name) .. "." .. method)
          end
        end
        if card.equip_skill ~= nil or type(card.dynamicEquipSkills) == "function" then
          contracts.equipmentSkillCount = contracts.equipmentSkillCount + 1
        end
        if type(card.dynamicAttackRange) == "function" then
          contracts.dynamicAttackRangeCount = contracts.dynamicAttackRangeCount + 1
          contracts.dynamicAttackRangeSmokeCount = contracts.dynamicAttackRangeSmokeCount + 1
          local rangeOk, attackRange = pcall(function() return card:getAttackRange(dynamicEquipmentProbe) end)
          local rangeValid = rangeOk and type(attackRange) == "number" and
            attackRange == attackRange and attackRange < math.huge and attackRange > -math.huge
          if not rangeValid then
            contracts.invalidDynamicAttackRangeSmokeTotal = contracts.invalidDynamicAttackRangeSmokeTotal + 1
            sample(contracts.invalidDynamicAttackRangeSmoke, tostring(card.name) .. ".dynamicAttackRange()")
          end
        end
        for _, lifecycle in ipairs({
          { name = "onInstall", invoke = function() return card:onInstall(equipmentLifecycleRoomProbe, equipmentLifecyclePlayerProbe) end },
          { name = "onUninstall", invoke = function() return card:onUninstall(equipmentLifecycleRoomProbe, equipmentLifecyclePlayerProbe) end },
        }) do
          contracts.equipmentLifecycleSmokeCount = contracts.equipmentLifecycleSmokeCount + 1
          local lifecycleOk = pcall(lifecycle.invoke)
          if not lifecycleOk then
            contracts.invalidEquipmentLifecycleSmokeTotal = contracts.invalidEquipmentLifecycleSmokeTotal + 1
            sample(contracts.invalidEquipmentLifecycleSmoke, tostring(card.name) .. "." .. lifecycle.name .. "()")
          end
        end
        if type(card.dynamicEquipSkills) == "function" then
          contracts.dynamicEquipmentCount = contracts.dynamicEquipmentCount + 1
          contracts.dynamicEquipmentSmokeCount = contracts.dynamicEquipmentSmokeCount + 1
          local dynamicOk, dynamicSkills = pcall(function() return card:getEquipSkills(dynamicEquipmentProbe) end)
          local dynamicSkillsValid = dynamicOk and type(dynamicSkills) == "table"
          if dynamicSkillsValid then
            for _, equipSkill in ipairs(dynamicSkills) do
              local equipSkillName = skillName(equipSkill)
              if not equipSkillName or not Fk.skills[equipSkillName] then
                dynamicSkillsValid = false
                break
              end
            end
          end
          if not dynamicSkillsValid then
            contracts.invalidDynamicEquipmentSmokeTotal = contracts.invalidDynamicEquipmentSmokeTotal + 1
            sample(contracts.invalidDynamicEquipmentSmoke, tostring(card.name) .. ".dynamicEquipSkills()")
          end
        else
          contracts.equipmentSmokeCount = contracts.equipmentSmokeCount + 1
          local equipOk, equipSkills = pcall(function() return card:getEquipSkills(nil) end)
          local equipSkillsValid = equipOk and type(equipSkills) == "table"
          if equipSkillsValid then
            for _, equipSkill in ipairs(equipSkills) do
              local equipSkillName = skillName(equipSkill)
              if not equipSkillName or not Fk.skills[equipSkillName] then
                equipSkillsValid = false
                break
              end
            end
          end
          if not equipSkillsValid then
            contracts.invalidEquipmentSmokeTotal = contracts.invalidEquipmentSmokeTotal + 1
            sample(contracts.invalidEquipmentSmoke, tostring(card.name) .. ".getEquipSkills()")
          end
        end
      end
      local refs = { card.skill, card.equip_skill }
      if type(card.equip_skills) == "table" then
        for _, equipSkill in ipairs(card.equip_skills) do refs[#refs + 1] = equipSkill end
      end
      for _, ref in ipairs(refs) do
        if ref ~= nil then
          contracts.cardSkillReferenceCount = contracts.cardSkillReferenceCount + 1
          local refName = skillName(ref)
          if not refName or not Fk.skills[refName] then
            contracts.invalidCardSkillsTotal = contracts.invalidCardSkillsTotal + 1
            sample(contracts.invalidCardSkills, tostring(card.name) .. ":" .. tostring(refName or ref))
          end
        end
      end
      if type(card.special_skills) == "table" then
        for _, ref in ipairs(card.special_skills) do
          contracts.cardSkillReferenceCount = contracts.cardSkillReferenceCount + 1
          local refName = skillName(ref)
          if not refName or not Fk.skills[refName] then
            contracts.invalidCardSkillsTotal = contracts.invalidCardSkillsTotal + 1
            sample(contracts.invalidCardSkills, tostring(card.name) .. ":" .. tostring(refName or ref))
          end
        end
      end
    end
  end
  if packageCardCount > 0 then contracts.cardPackageCount = contracts.cardPackageCount + 1 end
end

local used = {}
for _, general in ipairs(result.generals) do
  for _, skill in ipairs(general.refs) do used[skill] = true end
end
for name in pairs(Fk.skill_skels) do result.skeletonCount = result.skeletonCount + 1 end
for name in pairs(used) do
  result.skillExists[name] = Fk.skills[name] ~= nil
  local translatedName = Fk:translate(name)
  local translatedDescription = Fk:translate(":" .. name)
  result.translations[name] = {
    name = type(translatedName) == "string" and translatedName or "",
    description = type(translatedDescription) == "string" and translatedDescription or "",
  }
end
return result
`;

function ensureUpstream(): void {
  for (const spec of UPSTREAM_PACKAGE_NAMES.map(packageSpec)) {
    const root = path.join(UPSTREAM_ROOT, spec.sourceDirectory);
    assert.ok(existsSync(root), `Missing pinned upstream checkout: ${root}`);
  }
}

async function capture(
  packageNames: readonly string[],
  allowedNames?: Set<string>,
  patchDeclarations = true,
): Promise<RuntimeSnapshot> {
  const files = loadUpstreamFiles(UPSTREAM_ROOT, packageNames, { patchDeclarations });
  const runtime = new LuaRuntime({ files, callbacks: {
    send: () => {},
    setup: () => {},
    ui: () => {},
    log: (level, message) => {
      if (level === 'error') throw new Error(`Lua boot error: ${message}`);
    },
  }});
  try {
    await runtime.start();
    const allowed = allowedNames
      ? `{${[...allowedNames].map((name) => `[${JSON.stringify(name)}] = true`).join(',')}}`
      : 'nil';
    runtime.eval(`__web_skill_audit_allowed = ${allowed}; return true`);
    return runtime.eval<RuntimeSnapshot>(LUA_AUDIT);
  } finally {
    runtime.close();
  }
}

function sourceIndex(files: Map<string, Uint8Array>) {
  const exact = new Map<string, SourceLocation[]>();
  for (const [relativePath, bytes] of files) {
    if (!relativePath.endsWith('.lua')) continue;
    const [, packageName, ...fileParts] = relativePath.split('/');
    const spec = packageSpec(packageName);
    const lines = Buffer.from(bytes).toString('utf8').split(/\r?\n/u);
    for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      const expression = /\bname\s*=\s*(["'])([^"']+)\1/gu;
      for (const match of lines[lineIndex].matchAll(expression)) {
        const id = match[2];
        const locations = exact.get(id) ?? [];
        locations.push({
          upstreamPackage: spec.name,
          commit: spec.commit,
          file: fileParts.join('/'),
          line: lineIndex + 1,
        });
        exact.set(id, locations);
      }
    }
  }
  return exact;
}

function sortedUnique(values: Iterable<string>): string[] {
  return [...new Set(values)].sort((a, b) => a.localeCompare(b));
}

function summarize(snapshot: RuntimeSnapshot, allowedNames?: Set<string>): ReferenceSummary {
  const generals = snapshot.generals.filter((general) => !allowedNames || allowedNames.has(general.name));
  const references = generals.flatMap((general) => general.refs);
  const missingOccurrences = references.filter((id) => !snapshot.skillExists[id]).length;
  const missingIds = sortedUnique(references.filter((id) => !snapshot.skillExists[id]));
  const byPackage: ReferenceSummary['byPackage'] = {};
  for (const general of generals) {
    const entry = byPackage[general.package] ?? { generals: 0, directReferenceOccurrences: 0, missingIds: [] };
    entry.generals++;
    entry.directReferenceOccurrences += general.refs.length;
    entry.missingIds.push(...general.refs.filter((id) => !snapshot.skillExists[id]));
    byPackage[general.package] = entry;
  }
  for (const entry of Object.values(byPackage)) entry.missingIds = sortedUnique(entry.missingIds);
  return {
    generalCount: generals.length,
    visibleGeneralCount: generals.filter((general) => !general.hidden && !general.totalHidden).length,
    directReferenceOccurrences: references.length,
    directReferenceIds: new Set(references).size,
    missingOccurrences,
    missingIds,
    byPackage: Object.fromEntries(Object.entries(byPackage).sort(([a], [b]) => a.localeCompare(b))),
  };
}

function sourceLocationsForVariant(id: string, index: Map<string, SourceLocation[]>): SourceLocation[] {
  const matches: SourceLocation[] = [];
  for (const [name, locations] of index) {
    if (name === id) continue;
    if (name.endsWith(`__${id}`) || name.endsWith(`_${id}`)) matches.push(...locations);
  }
  return matches.sort((a, b) => `${a.upstreamPackage}/${a.file}:${a.line}`.localeCompare(`${b.upstreamPackage}/${b.file}:${b.line}`));
}

function declarationVersions(declarations: SkillMapping['declarations']): Array<{ name: string; commit: string }> {
  // Every one of the 203 baseline misses is declared by an internal Hegemony
  // package (standard, online_heg, overseas_heg, ...).  Record that owning
  // upstream pin explicitly; the exact implementation owner is listed
  // separately in exactImplementations.
  void declarations;
  return [{ name: 'hegemony', commit: packageSpec('hegemony').commit }];
}

function mappingFor(
  baseline: RuntimeSnapshot,
  complete: RuntimeSnapshot,
  allSource: Map<string, SourceLocation[]>,
  baselineNames: Set<string>,
  baselineMissingIds: Set<string>,
): SkillMapping[] {
  const baselineRefs = new Map<string, SkillMapping['declarations']>();
  for (const general of baseline.generals) {
    if (!baselineNames.has(general.name)) continue;
    for (const id of general.refs) {
      const declarations = baselineRefs.get(id) ?? [];
      declarations.push({
        general: general.name,
        trueName: general.trueName,
        package: general.package,
        visible: !general.hidden && !general.totalHidden,
      });
      baselineRefs.set(id, declarations);
    }
  }
  return [...baselineRefs.keys()].filter((id) => baselineMissingIds.has(id)).sort((a, b) => a.localeCompare(b)).map((id) => {
    const exact = allSource.get(id) ?? [];
    const variants = sourceLocationsForVariant(id, allSource);
    const runtimeResolved = complete.skillExists[id] === true;
    const repair = DECLARATION_REPAIRS.find((item) => item.fromSkill === id);
    const effectiveRuntimeResolved = runtimeResolved || Boolean(repair && complete.skillExists[repair.toSkill]);
    const exactDependency = exact.some((location) => !BASELINE_PACKAGE_NAMES.includes(location.upstreamPackage as typeof BASELINE_PACKAGE_NAMES[number]));
    const exactBaseline = exact.some((location) => BASELINE_PACKAGE_NAMES.includes(location.upstreamPackage as typeof BASELINE_PACKAGE_NAMES[number]));
    let classification: MappingClassification;
    let reason: string;
    if (repair && complete.skillExists[repair.toSkill]) {
      classification = 'declaration-repaired';
      reason = `Pinned declaration was repaired from ${repair.fromSkill} to exact ${repair.toSkill} from ${repair.ownerPackage}@${repair.ownerCommit}.`;
    } else if (runtimeResolved && exactDependency) {
      classification = 'resolved-by-dependency';
      reason = 'Exact skill implementation is loaded from a pinned dependency package.';
    } else if (runtimeResolved && exactBaseline) {
      classification = 'resolved-in-baseline';
      reason = 'Exact skill implementation is already present in the baseline package set.';
    } else if (exactBaseline) {
      classification = 'declaration-not-loaded';
      reason = 'An exact source declaration exists in a baseline checkout but is not registered in Fk.skills at boot; inspect package loading/declaration order.';
    } else if (variants.length > 0) {
      classification = 'declaration-variant-review';
      reason = 'Only a prefixed/variant implementation was found. The declaration must not be aliased until its rules and upstream version are reviewed.';
    } else {
      classification = 'implementation-missing';
      reason = 'No exact or variant implementation was found in the pinned source trees.';
    }
    return {
      id,
      occurrences: baselineRefs.get(id)!.length,
      declarations: baselineRefs.get(id)!,
      classification,
      declarationUpstream: declarationVersions(baselineRefs.get(id)! ),
      exactImplementations: exact,
      variantCandidates: variants,
      runtimeResolved,
      effectiveRuntimeResolved,
      replacement: repair?.toSkill,
      reason,
    };
  });
}

function auditTranslations(
  snapshot: RuntimeSnapshot,
  visibleNames: Set<string>,
  additions: Record<string, string>,
): TranslationAudit {
  const refs = new Set<string>();
  for (const general of snapshot.generals) {
    if (!visibleNames.has(general.name) || general.hidden || general.totalHidden) continue;
    for (const id of general.refs) refs.add(id);
  }
  const rawNames: string[] = [];
  const cjkNames: string[] = [];
  const rawDescriptions: string[] = [];
  const cjkDescriptions: string[] = [];
  const entries: Record<string, TranslationRecord> = {};
  for (const id of [...refs].sort((a, b) => a.localeCompare(b))) {
    const upstream = snapshot.translations[id] ?? { name: '', description: '' };
    // This is the effective display table: host additions are loaded after
    // the upstream vi/zh/en tables and therefore take precedence at runtime.
    const translation = {
      name: additions[id] ?? upstream.name,
      description: additions[`:${id}`] ?? upstream.description,
    };
    entries[id] = translation;
    if (!translation.name || translation.name === id) rawNames.push(id);
    if (CJK.test(translation.name)) cjkNames.push(id);
    if (!translation.description || translation.description === `:${id}`) rawDescriptions.push(id);
    if (CJK.test(translation.description)) cjkDescriptions.push(id);
  }
  return {
    referencedIds: refs.size,
    translatedNames: refs.size - rawNames.length - cjkNames.filter((id) => !rawNames.includes(id)).length,
    translatedDescriptions: refs.size - rawDescriptions.length - cjkDescriptions.filter((id) => !rawDescriptions.includes(id)).length,
    entries,
    rawNames, cjkNames, rawDescriptions, cjkDescriptions,
  };
}

function printReport(report: AuditReport): void {
  const { baseline, dependencyComplete, dependencyCompleteVisible: visible, invariant, translation } = report;
  const contracts = report.runtimeContracts;
  console.log(`Skill audit: baseline ${baseline.directReferenceIds} IDs / ${baseline.missingIds.length} unresolved; ` +
    `dependency-complete ${dependencyComplete.directReferenceIds} IDs / ${dependencyComplete.missingIds.length} unresolved; ` +
    `visible unresolved ${visible.missingIds.length}`);
  const invalidContractCount = contracts.activeInvalidGeneralSkillsTotal + contracts.invalidSkillsTotal +
    contracts.invalidSkillSmokeTotal + contracts.invalidCardsTotal + contracts.invalidCardSmokeTotal +
    contracts.invalidEquipmentSmokeTotal + contracts.invalidDynamicEquipmentSmokeTotal +
    contracts.invalidDynamicAttackRangeSmokeTotal + contracts.invalidCardSkillsTotal;
  console.log(`Runtime contract audit: ${contracts.generalCount} generals (${contracts.visibleGeneralCount} visible; ` +
    `${contracts.activeGeneralCount} active in new_heg_mode; ${contracts.generalSkillReferenceCount} declared skill refs), ` +
    `${contracts.skillCount} skills / ${contracts.skillSmokeCount} no-side-effect skill smoke calls, ` +
    `${contracts.cardCount} playable cards + ${contracts.derivedCardCount} derived cards / ${contracts.cardSmokeCount} card smoke calls, ` +
    `${contracts.equipmentCount} equipment cards / ${contracts.equipmentSmokeCount + contracts.dynamicEquipmentSmokeCount} equipment skill smoke calls ` +
    `(${contracts.equipmentSmokeCount} static + ${contracts.dynamicEquipmentSmokeCount} dynamic), ` +
    `${contracts.dynamicAttackRangeSmokeCount} dynamic attack-range smoke calls, ` +
    `${contracts.equipmentLifecycleSmokeCount} equipment lifecycle smoke calls, ` +
    `${contracts.cardSkillReferenceCount} card-skill refs; ` +
    `${invalidContractCount} active-mode invalid contracts (${contracts.invalidGeneralSkillsTotal + contracts.invalidSkillsTotal + contracts.invalidSkillSmokeTotal + contracts.invalidCardsTotal + contracts.invalidCardSmokeTotal + contracts.invalidEquipmentSmokeTotal + contracts.invalidDynamicEquipmentSmokeTotal + contracts.invalidDynamicAttackRangeSmokeTotal + contracts.invalidEquipmentLifecycleSmokeTotal + contracts.invalidCardSkillsTotal} across all loaded packages)`);
  console.log(`Skill classes: ${Object.entries(contracts.skillClassCounts).sort(([a], [b]) => a.localeCompare(b))
    .map(([name, count]) => `${name || '<unknown>'}=${count}`).join(', ')}`);
  console.log(`Packages: ${report.packages.map((spec) => `${spec.name}@${spec.commit.slice(0, 12)}`).join(', ')}`);
  console.log(`Translation audit: ${translation.referencedIds} referenced; ` +
    `${translation.rawNames.length + translation.cjkNames.length} names and ` +
    `${translation.rawDescriptions.length + translation.cjkDescriptions.length} descriptions need review by the current heuristic.`);
  const counts = new Map<string, number>();
  for (const item of report.mapping) counts.set(item.classification, (counts.get(item.classification) ?? 0) + 1);
  console.log(`Mapping: ${[...counts.entries()].map(([name, count]) => `${name}=${count}`).join(', ')}`);
  for (const item of report.mapping.filter((entry) => !entry.effectiveRuntimeResolved)) {
    const packages = sortedUnique(item.declarations.map((declaration) => declaration.package)).join(', ');
    const variants = item.variantCandidates.map((location) => `${location.upstreamPackage}/${location.file}:${location.line}`).join(', ');
    console.log(`UNRESOLVED ${item.id} [${packages}]${variants ? ` variants=${variants}` : ''}`);
  }
  for (const item of report.mapping.filter((entry) => entry.classification === 'declaration-repaired')) {
    console.log(`REPAIRED ${item.id} -> ${item.replacement}`);
  }
  console.log(invariant.pass ? 'PASS skill invariant' : 'FAIL skill invariant: visible general has unresolved direct skill reference');
  if (contracts.invalidGeneralSkillsTotal)
    console.log(`INVALID GENERAL SKILLS (all loaded packages): ${contracts.invalidGeneralSkills.join(', ')}`);
  if (contracts.inactiveInvalidGeneralSkillsTotal)
    console.log(`INFO disabled-package general skills (excluded from new_heg_mode): ${contracts.inactiveInvalidGeneralSkills.join(', ')}`);
  if (invalidContractCount) {
    console.log(`FAIL runtime contracts in new_heg_mode: generals=${contracts.activeInvalidGeneralSkillsTotal}, skills=${contracts.invalidSkillsTotal}, ` +
      `skillSmoke=${contracts.invalidSkillSmokeTotal}, cards=${contracts.invalidCardsTotal}, ` +
      `cardSmoke=${contracts.invalidCardSmokeTotal}, equipmentSmoke=${contracts.invalidEquipmentSmokeTotal}, ` +
      `dynamicEquipmentSmoke=${contracts.invalidDynamicEquipmentSmokeTotal}, ` +
      `dynamicAttackRangeSmoke=${contracts.invalidDynamicAttackRangeSmokeTotal}, ` +
      `equipmentLifecycleSmoke=${contracts.invalidEquipmentLifecycleSmokeTotal}, ` +
      `cardSkills=${contracts.invalidCardSkillsTotal}`);
  } else {
    console.log('PASS runtime contracts: generals, skills, equipment and cards are structurally executable');
  }
}

function renderMarkdown(report: AuditReport): string {
  const lines = [
    '# CP19 skill inventory and upstream mapping',
    '',
    'This report is generated from the pinned Lua runtime. The baseline inventory audits `General.other_skills` directly; the runtime contract audit checks every General skill collection. It is intentionally not based on `General:getSkillNameList()`, which drops unresolved strings.',
    '',
    `- Baseline: ${report.baseline.generalCount} identities / ${report.baseline.visibleGeneralCount} visible / ${report.baseline.directReferenceIds} unique direct IDs / ${report.baseline.missingIds.length} missing IDs (${report.baseline.missingOccurrences} occurrences).`,
    `- Dependency-complete scoped runtime: ${report.dependencyCompleteSkillCount} registered skills; ${report.dependencyComplete.missingIds.length} unresolved direct IDs across the original ${report.dependencyComplete.generalCount} generals.`,
    `- Visible invariant: ${report.dependencyCompleteVisible.missingIds.length === 0 ? 'PASS' : 'FAIL'}; unresolved visible IDs: ${report.dependencyCompleteVisible.missingIds.length ? report.dependencyCompleteVisible.missingIds.join(', ') : 'none'}.`,
    `- Runtime contract audit: ${report.runtimeContracts.generalCount} generals / ${report.runtimeContracts.skillCount} skills / ${report.runtimeContracts.cardCount} playable cards / ${report.runtimeContracts.derivedCardCount} derived cards / ${report.runtimeContracts.equipmentCount} equipment cards; invalid contracts: ${report.runtimeContracts.invalidGeneralSkillsTotal + report.runtimeContracts.invalidSkillsTotal + report.runtimeContracts.invalidSkillSmokeTotal + report.runtimeContracts.invalidCardsTotal + report.runtimeContracts.invalidCardSmokeTotal + report.runtimeContracts.invalidEquipmentSmokeTotal + report.runtimeContracts.invalidDynamicEquipmentSmokeTotal + report.runtimeContracts.invalidDynamicAttackRangeSmokeTotal + report.runtimeContracts.invalidEquipmentLifecycleSmokeTotal + report.runtimeContracts.invalidCardSkillsTotal}.`,
    `- Skill smoke: ${report.runtimeContracts.skillSmokeCount} no-side-effect calls; failures: ${report.runtimeContracts.invalidSkillSmokeTotal}.`,
    `- Card/equipment smoke: ${report.runtimeContracts.cardSmokeCount} card calls, ${report.runtimeContracts.equipmentSmokeCount + report.runtimeContracts.dynamicEquipmentSmokeCount} equipment skill calls (${report.runtimeContracts.equipmentSmokeCount} static + ${report.runtimeContracts.dynamicEquipmentSmokeCount} dynamic), ${report.runtimeContracts.dynamicAttackRangeSmokeCount} dynamic attack-range calls, and ${report.runtimeContracts.equipmentLifecycleSmokeCount} lifecycle calls; failures: ${report.runtimeContracts.invalidCardSmokeTotal + report.runtimeContracts.invalidEquipmentSmokeTotal + report.runtimeContracts.invalidDynamicEquipmentSmokeTotal + report.runtimeContracts.invalidDynamicAttackRangeSmokeTotal + report.runtimeContracts.invalidEquipmentLifecycleSmokeTotal}.`,
    `- Translation re-audit: ${report.translation.referencedIds} visible direct IDs; CJK heuristic remains ${report.translation.cjkNames.length} names and ${report.translation.cjkDescriptions.length} descriptions.`,
    '',
    '## Pinned upstream versions',
    '',
    '| Runtime package | Commit | Role |',
    '| --- | --- | --- |',
    ...report.packages.map((spec) => `| \`${spec.name}\` | \`${spec.commit}\` | ${spec.role} |`),
    '',
    '## 203-ID mapping',
    '',
    'The declaration column is the internal package that exposed the missing string. The implementation column records the first exact pinned source location (and all exact owners when more than one exists). A `declaration-repaired` row is an evidence-backed rename to an exact owner; no variant rules are copied or aliased.',
    '',
    `Classification counts: ${[...report.mapping.reduce((counts, item) => counts.set(item.classification, (counts.get(item.classification) ?? 0) + 1), new Map<MappingClassification, number>())].map(([classification, count]) => `\`${classification}\`=${count}`).join(', ')}.`,
    '',
    '| ID | Declaration package @ upstream | Occurrences | Classification | Exact implementation / repair evidence |',
    '| --- | --- | ---: | --- | --- |',
  ];
  for (const item of report.mapping) {
    const declarationPackages = item.declarationUpstream
      .map((declaration) => `\`${declaration.name}@${declaration.commit}\``).join(', ');
    const exact = item.exactImplementations.map((location) =>
      `\`${location.upstreamPackage}@${location.commit.slice(0, 12)} ${location.file}:${location.line}\``).join('<br>');
    const variants = item.variantCandidates.map((location) =>
      `variant \`${location.upstreamPackage}@${location.commit.slice(0, 12)} ${location.file}:${location.line}\``).join('<br>');
    const repair = item.replacement ? `\`${item.id}\` → \`${item.replacement}\`; ` : '';
    lines.push(`| \`${item.id}\` | ${declarationPackages} | ${item.occurrences} | ${item.classification} | ${repair}${exact || variants} |`);
  }
  lines.push('', '## Gate', '', 'The release build invokes `npm run audit:skills` before TypeScript/Vite compilation. It exits non-zero whenever a baseline visible general has a direct skill string absent from `Fk.skills`, or when an active `new_heg_mode` general reference from any General skill collection, registered skill, equipment skill, or card skill reference fails the runtime contract audit. Disabled-package declarations remain visible in the report and are not silently repaired.', '');
  return lines.join('\n');
}

async function main(): Promise<AuditReport> {
  const reportOnly = process.argv.includes('--report-only');
  ensureUpstream();
  const baseline = await capture(BASELINE_PACKAGE_NAMES, undefined, false);
  const baselineNames = new Set(baseline.generals.map((general) => general.name));
  const baselineVisibleNames = new Set(baseline.generals
    .filter((general) => !general.hidden && !general.totalHidden)
    .map((general) => general.name));
  const complete = await capture(UPSTREAM_PACKAGE_NAMES, baselineNames);
  const baselineSummary = summarize(baseline);
  const completeSummary = summarize(complete, baselineNames);
  const completeVisibleSummary = summarize(complete, baselineVisibleNames);
  assert.equal(baselineSummary.missingIds.length, 203,
    `Pinned baseline missing-ID inventory drifted: expected 203, got ${baselineSummary.missingIds.length}`);
  assert.equal(baselineSummary.missingOccurrences, 205,
    `Pinned baseline missing occurrence inventory drifted: expected 205, got ${baselineSummary.missingOccurrences}`);
  const source = sourceIndex(loadUpstreamFiles(UPSTREAM_ROOT, UPSTREAM_PACKAGE_NAMES, { patchDeclarations: false }));
  const mapping = mappingFor(baseline, complete, source, baselineNames, new Set(baselineSummary.missingIds));
  const translation = auditTranslations(complete, baselineVisibleNames, VI_ADDITIONS);
  const unresolvedVisibleIds = completeVisibleSummary.missingIds;
  const runtimeContracts = complete.runtimeContracts;
  if (!reportOnly) {
    assert.equal(runtimeContracts.activeInvalidGeneralSkillsTotal, 0,
      `Runtime active general skill contract failures: ${runtimeContracts.activeInvalidGeneralSkills.join(', ')}`);
    assert.equal(runtimeContracts.invalidSkillsTotal, 0,
      `Runtime skill contract failures: ${runtimeContracts.invalidSkills.join(', ')}`);
    assert.equal(runtimeContracts.invalidSkillSmokeTotal, 0,
      `Runtime skill smoke failures: ${runtimeContracts.invalidSkillSmoke.join(', ')}`);
    assert.equal(runtimeContracts.invalidCardSmokeTotal, 0,
      `Runtime card smoke failures: ${runtimeContracts.invalidCardSmoke.join(', ')}`);
    assert.equal(runtimeContracts.invalidEquipmentSmokeTotal, 0,
      `Runtime equipment smoke failures: ${runtimeContracts.invalidEquipmentSmoke.join(', ')}`);
    assert.equal(runtimeContracts.invalidDynamicEquipmentSmokeTotal, 0,
      `Runtime dynamic equipment smoke failures: ${runtimeContracts.invalidDynamicEquipmentSmoke.join(', ')}`);
    assert.equal(runtimeContracts.invalidDynamicAttackRangeSmokeTotal, 0,
      `Runtime dynamic attack-range smoke failures: ${runtimeContracts.invalidDynamicAttackRangeSmoke.join(', ')}`);
    assert.equal(runtimeContracts.invalidEquipmentLifecycleSmokeTotal, 0,
      `Runtime equipment lifecycle smoke failures: ${runtimeContracts.invalidEquipmentLifecycleSmoke.join(', ')}`);
    assert.equal(runtimeContracts.invalidCardsTotal, 0,
      `Runtime card contract failures: ${runtimeContracts.invalidCards.join(', ')}`);
    assert.equal(runtimeContracts.invalidCardSkillsTotal, 0,
      `Runtime card-skill contract failures: ${runtimeContracts.invalidCardSkills.join(', ')}`);
  }
  const invalidContractCount = runtimeContracts.activeInvalidGeneralSkillsTotal + runtimeContracts.invalidSkillsTotal +
    runtimeContracts.invalidSkillSmokeTotal + runtimeContracts.invalidCardsTotal + runtimeContracts.invalidCardSmokeTotal +
    runtimeContracts.invalidEquipmentSmokeTotal + runtimeContracts.invalidDynamicEquipmentSmokeTotal +
    runtimeContracts.invalidDynamicAttackRangeSmokeTotal + runtimeContracts.invalidEquipmentLifecycleSmokeTotal +
    runtimeContracts.invalidCardSkillsTotal;
  return {
    generatedAt: new Date().toISOString(),
    upstreamRoot: UPSTREAM_ROOT,
    packages: UPSTREAM_PACKAGE_NAMES.map(packageSpec),
    baseline: baselineSummary,
    dependencyComplete: completeSummary,
    dependencyCompleteVisible: completeVisibleSummary,
    baselineSkillCount: baseline.skillCount,
    dependencyCompleteSkillCount: complete.skillCount,
    dependencyCompleteSkeletonCount: complete.skeletonCount,
    runtimeContracts,
    mapping,
    translation,
    invariant: {
      baselineMissingIdsExpected: 203,
      baselineMissingIdsActual: baselineSummary.missingIds.length,
      unresolvedVisibleIds,
      pass: unresolvedVisibleIds.length === 0 && invalidContractCount === 0,
    },
  };
}

const report = await main();
if (process.argv.includes('--json')) console.log(JSON.stringify(report, null, 2));
else if (process.argv.includes('--markdown')) console.log(renderMarkdown(report));
else printReport(report);
if (!report.invariant.pass && !process.argv.includes('--report-only')) process.exitCode = 1;
