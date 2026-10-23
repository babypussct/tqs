-- Initial new_heg_mode general-pair selection. This module only reads the
-- offered generals, their published definitions and the enabled kingdoms.
-- It never inspects another seat, hidden hands, or room game state.

local M = {}

-- Tunable coefficients. Scores are heuristics, NOT estimated win probabilities.
M.weights = {
  individual = 1.0, synergy = 1.3, survivability = 1.0,
  offense = 1.0, support = 1.0, hegemony = 1.0,
}

-- Explicitly modeled skills from the pinned Hegemony rules. Absent skills
-- receive a small generic contribution, so new packs can be added safely.
-- power, draw, attack, defense, heal, support, setup, slash, equipment
M.skills = {
  hs__zhiheng = { power = 1.4, draw = 1.5 },
  hs__jizhi = { power = 1.3, draw = 1.4 },
  hs__guanxing = { power = 1.2, setup = 1.6 },
  hs__luoshen = { power = 1.2, draw = 1.4, setup = 0.5 },
  hs__paoxiao = { power = 1.1, attack = 1.5 },
  hs__wusheng = { power = 1.0, attack = 0.9, slash = 1.3 },
  hs__longdan = { power = 1.0, attack = 0.6, defense = 0.5, slash = 1.1 },
  hs__kurou = { power = 0.7, draw = 1.2, attack = 0.2 },
  hs__qianxun = { power = 1.0, defense = 1.1 },
  hs__kongcheng = { power = 0.9, defense = 1.1 },
  hs__buqu = { power = 1.2, defense = 1.5 },
  hs__tianxiang = { power = 1.1, defense = 1.1, support = 0.5 },
  hs__yiji = { power = 1.1, draw = 0.8, support = 1.5 },
  hs__xiaoji = { power = 1.0, draw = 1.2, equipment = 1.4 },
  hs__keji = { power = 0.9, defense = 0.5, draw = 0.5 },
  huoshui = { power = 1.0, attack = 0.6 },
  -- Source-checked skills in the pinned enabled Hegemony pool. These are
  -- conservative priors for pair selection, not estimates of skill win rate.
  duanbing = { power = 0.8, attack = 1.0 }, -- extra adjacent Slash target
  ld__tunjiang = { power = 0.7, draw = 0.5 }, -- conditional end-phase draw
  qixi = { power = 0.9, attack = 0.5 }, -- black card -> Dismantlement
  shangyi = { power = 0.8, attack = 0.3 }, -- reveal/discard once per phase
  shoucheng = { power = 0.8, support = 1.0, draw = 0.3 }, -- allied empty hand
  tianyi = { power = 0.8, attack = 0.7, slash = 0.3 }, -- duel-gated Slash buff
  tiaoxin = { power = 0.7, attack = 0.5 }, -- provoke Slash or discard
  yizhi = { power = 0.9, setup = 1.0 }, -- deputy-only Guanxing behavior
}

-- Known complementary interactions in the selected Hegemony snapshot.
M.combinations = {
  ['hs__paoxiao|hs__wusheng'] = 2.4, -- extra Slashes + multiple Slashes
  ['hs__longdan|hs__paoxiao'] = 2.2, -- Jink conversion fuels Slashes
  ['hs__guanxing|hs__luoshen'] = 2.0, -- top-deck setup + judgment draw
  ['hs__kurou|hs__paoxiao'] = 1.1, -- card access costs HP
}

local function add(t, key, delta)
  t[key] = (t[key] or 0) + delta
end

local function skillsFor(general, isMain, alreadyCounted)
  local stats = { power = 0, draw = 0, attack = 0, defense = 0,
    heal = 0, support = 0, setup = 0, slash = 0, equipment = 0 }
  local names = {}
  local ok, list = pcall(general.getSkillNameList, general, true)
  if not ok or type(list) ~= 'table' then return stats, names end
  for _, name in ipairs(list) do
    local skill = Fk.skills[name]
    local allowed = skill and type(skill.hasTag) == 'function' and
      not (alreadyCounted and alreadyCounted[name]) and not names[name]
    -- The mode attaches skills by name (addFakeSkill); identical skills on
    -- both generals do not become two independent copies of the same effect.
    if allowed then
      local valid, restricted = pcall(skill.hasTag, skill,
        isMain and Skill.DeputyPlace or Skill.MainPlace)
      allowed = valid and not restricted
    end
    if allowed then
      names[name] = true
      local trait = M.skills[name] or { power = 0.35 }
      for key, value in pairs(trait) do add(stats, key, value) end
    end
  end
  return stats, names
end

local function validOffer(data)
  if type(data) ~= 'table' or type(data.component) ~= 'table' then return nil end
  local component = data.component
  if component.name ~= 'ChooseInitialGeneralBox' or type(component.model) ~= 'table' or
      component.model.name ~= 'ChooseInitialGeneralModel' then return nil end
  local props = component.model.prop
  if type(props) ~= 'table' or props.hegemony ~= true or props.choiceNum ~= 2 or
      type(props.generals) ~= 'table' or type(props.enabledKingdoms) ~= 'table' then return nil end
  if #props.generals < 2 then return nil end
  for i, name in ipairs(props.generals) do
    if type(name) ~= 'string' or not Fk.generals[name] then return nil end
  end
  return props
end

local function legalKingdoms(a, b, kingdoms)
  local ok, match = pcall(Fk.canMatchInHegemony, Fk, a, b, kingdoms)
  if not ok or not match then return nil end
  local success, options = pcall(Fk.getKingdomInHegemony, Fk, a, b, kingdoms)
  if not success or type(options) ~= 'table' or #options == 0 then return nil end
  -- A wild lord can match a deputy but still needs a permitted real kingdom.
  local enabled = {}
  for _, kingdom in ipairs(kingdoms) do enabled[kingdom] = true end
  local result, seen = {}, {}
  for _, kingdom in ipairs(options) do
    if type(kingdom) == 'string' and enabled[kingdom] and not seen[kingdom] then
      result[#result + 1] = kingdom
      seen[kingdom] = true
    end
  end
  table.sort(result)
  if #result == 0 then return nil end
  return result
end

function M.score(a, b)
  local main, deputy = Fk.generals[a], Fk.generals[b]
  local x, mainSkills = skillsFor(main, true)
  local y, deputySkills = skillsFor(deputy, false, mainSkills)
  local traits = {}
  for _, key in ipairs({'power','draw','attack','defense','heal','support','setup','slash','equipment'}) do
    traits[key] = x[key] + y[key]
  end

  local synergy = math.min(x.draw * y.attack + y.draw * x.attack, 4) * 0.33 +
    math.min(x.setup * y.draw + y.setup * x.draw, 4) * 0.40 +
    math.min(x.slash * y.attack + y.slash * x.attack, 4) * 0.30
  for k in pairs(mainSkills) do
    for v in pairs(deputySkills) do
      local pairKey = k < v and (k .. '|' .. v) or (v .. '|' .. k)
      synergy = synergy + (M.combinations[pairKey] or 0)
    end
  end
  local effectiveHp = (main.maxHp + (main.mainMaxHpAdjustedValue or 0) +
    deputy.maxHp + (deputy.deputyMaxHpAdjustedValue or 0))
  local hp = math.floor(effectiveHp / 2)
  local companion = false
  if type(main.isCompanionWith) == 'function' then
    local ok, matched = pcall(main.isCompanionWith, main, deputy)
    companion = ok and matched or false
  end
  local components = {
    individual = traits.power,
    synergy = synergy,
    survivability = hp * 1.10 + traits.defense * 1.2 + traits.heal * 1.1,
    offense = traits.attack * 1.3 + traits.slash * 0.5 + traits.draw * 0.35,
    support = traits.support * 1.4,
    hegemony = (companion and 1.7 or 0) + (effectiveHp % 2 == 1 and 0.6 or 0)
      + (main.kingdom == 'wild' and -0.5 or 0),
  }
  local total = 0
  for key, value in pairs(components) do total = total + value * M.weights[key] end
  return total, components
end

function M.choose(data)
  local props = validOffer(data)
  if not props then return nil end
  local best, bestScore, bestKey
  for _, a in ipairs(props.generals) do
    for _, b in ipairs(props.generals) do
      if a ~= b then
        local kingdoms = legalKingdoms(a, b, props.enabledKingdoms)
        if kingdoms then
          -- All legal kingdoms have the same known initial pair score. Choose
          -- one deterministically while retaining the full legal set for QA.
          local kingdom = kingdoms[1]
          -- Broken/incomplete public definitions can prevent heuristic
          -- scoring; keep the server-law-legal pair as a deterministic
          -- fallback. All scored candidates outrank such fallback pairs.
          local scored, score = pcall(M.score, a, b)
          if not scored or type(score) ~= 'number' or score ~= score or
              math.abs(score) == math.huge then
            score = -math.huge
          end
          local key = a .. ',' .. b .. ',' .. kingdom
          if not best or score > bestScore + 1e-8 or
              ((score == bestScore or math.abs(score - bestScore) <= 1e-8) and key < bestKey) then
            best, bestScore, bestKey = { a .. ',' .. b, 'kingdom,' .. kingdom }, score, key
          end
        end
      end
    end
  end
  return best, bestScore
end

function M.validate(data, reply)
  local props = validOffer(data)
  if not props or type(reply) ~= 'table' or #reply ~= 2 or
      type(reply[1]) ~= 'string' or type(reply[2]) ~= 'string' then return false end
  local a, b = reply[1]:match('^([^,]+),([^,]+)$')
  local kingdom = reply[2]:match('^kingdom,([^,]+)$')
  if not a or not b or not kingdom or a == b then return false end
  local offered = {}
  for _, g in ipairs(props.generals) do offered[g] = true end
  if not offered[a] or not offered[b] then return false end
  for _, allowed in ipairs(legalKingdoms(a, b, props.enabledKingdoms) or {}) do
    if allowed == kingdom then return true end
  end
  return false
end

return M
