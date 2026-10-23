-- SPDX-License-Identifier: GPL-3.0-or-later

---@class SmartAI.Memory : { [string]: any }
---@field intentionScore table<SmartAI.Intention, number> 行动意向打分

---@class SmartAI: TrustAI, AIUtil
---@field public mem SmartAI.Memory @ 暂存某些值避免重复计算
local SmartAI = TrustAI:subclass("SmartAI")

local AIUtil = require 'ltk.server.ai.util'
SmartAI:include(AIUtil)

local AIGameLogic, AIGameEvent = require "ltk.server.ai.logic"
local AI = require "ltk.server.ai.strategies"
local FactionInference = require "ltk.server.ai.faction_inference"
local GeneralPair = require "ltk.server.ai.general_pair"

-- QA-only baseline switch for Prompt 4 A/B probes. It is deliberately
-- server-config gated and leaves the default candidate behavior unchanged;
-- production configs do not set this key. The switch removes only the
-- selected Prompt 4 strategy registrations from lookup, so the normal
-- default handler/fallback path remains the comparison baseline.
local PROMPT4_BASELINE_SKILLS = {
  tianyi = true, shangyi = true, tiaoxin = true,
  hs__zhiheng = true, hs__kurou = true, hs__qiangxi = true,
  hs__longdan = true, hs__luanji = true, hs__wusheng = true,
  huoji = true, jijiu = true, kanpo = true,
  aocai = true, beizhu = true, dimeng = true,
  choufa = true, cunsi = true, duanfa = true,
}

local function prompt4BaselineEnabled()
  return type(ServerConfig) == "table" and ServerConfig.tqsPrompt4Baseline == true
end

local function markFallback(ai, reason)
  if ai.markFallback then ai:markFallback(reason) end
end

-- A PlayCard strategy may fail while another strategy still returns a usable
-- action. Isolated QA rooms record the failing strategy separately from the
-- final request outcome, with only the 18 allowlisted skill labels retained.
local function recordPrompt4StrategyIssues(ai, failedSkills, recovered)
  if type(ServerConfig) ~= "table" or type(ServerConfig.tqsQa) ~= "table" or
      ServerConfig.tqsQa.enabled ~= true or #failedSkills == 0 then return end
  local room = ai.room
  if not room or type(room.getTag) ~= "function" or
      type(room.setTag) ~= "function" then return end
  local issues = room:getTag("__tqs_prompt4_strategy_issues")
  if type(issues) ~= "table" then issues = {} end
  for _, name in ipairs(failedSkills) do
    local safeName = PROMPT4_BASELINE_SKILLS[name] and name or "other"
    local bucket = issues[safeName] or { total = 0, recovered = 0, unrecovered = 0 }
    bucket.total = bucket.total + 1
    local field = recovered and "recovered" or "unrecovered"
    bucket[field] = bucket[field] + 1
    issues[safeName] = bucket
  end
  room:setTag("__tqs_prompt4_strategy_issues", issues)
end

local function promptParts(prompt)
  if type(prompt) ~= "string" or prompt == "" then return nil end
  return prompt:split(":")
end

local function promptPart(prompt, index)
  local parts = promptParts(prompt)
  if not parts then return nil end
  local value = parts[index]
  return value ~= "" and value or nil
end

-- The pinned server format is #AskForChooseCard:<target>::<skill>.  Keep the
-- fixed position for that known format, but accept a final ASCII skill token
-- for older/custom prompts instead of indexing an unchecked split result.
local function cardChosenReason(prompt)
  local parts = promptParts(prompt)
  if not parts then return nil end
  if parts[1] == "#AskForChooseCard" then
    return parts[4] ~= "" and parts[4] or nil
  end
  -- Beizhu asks for the target's card with a legacy prompt that contains only
  -- the target id.  Keep the mapping local to the request adapter; the Lua
  -- skill still owns the card visibility and discard rules.
  if parts[1] == "#beizhu-throw" then return "beizhu" end
  for i = #parts, 2, -1 do
    if parts[i] ~= "" and parts[i]:match("^[%w_]+$") then
      return parts[i]
    end
  end
  return nil
end

local function nullificationTargetId(prompt)
  if type(prompt) ~= "string" then return nil end
  if prompt:startsWith("#AskForNullificationWithoutTo") then
    return promptPart(prompt, 2)
  end
  return promptPart(prompt, 3)
end

local function peachTargetId(prompt)
  if type(prompt) ~= "string" then return nil end
  return promptPart(prompt, 2)
end

local function safePlayerById(room, id)
  local numeric_id = tonumber(id)
  if not room or numeric_id == nil or type(room.getPlayerById) ~= "function" then return nil end
  local ok, player = pcall(room.getPlayerById, room, numeric_id)
  return ok and player or nil
end

local function safeCardById(id)
  local numeric_id = tonumber(id)
  if numeric_id == nil or not Fk or type(Fk.getCardById) ~= "function" then return nil end
  local ok, card = pcall(Fk.getCardById, Fk, numeric_id)
  return ok and card or nil
end

-- AskForUseCard is also used for a physical card whose parent skill supplied
-- the request reason.  Select the card and then the first server-enabled
-- target through the real request handler; do not construct a reply from
-- target ids or bypass card feasibility.  The handler has already filtered
-- private cards and the server-provided extra_data (must/exclusive targets)
-- remains the source of truth.
local function tryPhysicalCardUse(ai, pattern, card_ids)
  if ai.handler and ai.handler.skill_name then return nil end
  local expression = Exppattern:Parse(pattern)
  for _, id in ipairs(card_ids) do
    local card = safeCardById(id)
    if card and expression:match(card) then
      ai:selectCard(id, true)
      local targets = ai:getEnabledTargets()
      if #targets > 0 then
        ai:selectTarget(targets[1], true)
      end
      local reply = ai:doOKButton()
      if reply ~= "" then return reply end
      ai:unSelectAll()
    end
  end
  return nil
end

function SmartAI:initialize(player)
  TrustAI.initialize(self, player)
  self.factionInference = FactionInference.new(self)
end

function SmartAI:makeReply()
  self.mem = setmetatable({}, { __mode = "k" })
  return TrustAI.makeReply(self)
end

-- The initial Hegemony CustomDialog is the only CustomDialog we handle.
-- Unknown mini-games and post-game general dialogs retain server fallback.
function SmartAI:handleCustomDialog(data)
  local reply = GeneralPair.choose(data)
  if not reply then
    self:markFallback('no_decision')
    return nil
  end
  return reply
end

--- 解析对整个策略的复用，技能和类型由spec指定
---@param spec AIReuseSpec
---@param stack any? 避免循环依赖
---@return AIStrategy?
local function resolveStrategyReuse(spec, stack)
  stack = stack or {}
  if stack[spec] then
    fk.qWarning("AI strategy reuse loop detected (=> %s)", spec._reuse_key)
    return nil
  end
  stack[spec] = true

  local skill = Fk.skills[spec._reuse_key]
  if not skill then return end
  local skel = skill:getSkeleton()
  if not skel then return end

  local resolved
  local reuse_tp = spec._reuse_type
  if not reuse_tp then
    fk.qWarning("reuse: no strategy type specified")
    stack[spec] = nil
    return nil
  end

  local list = skel.ai_strategies[reuse_tp] or Util.DummyTable
  resolved = list[1]
  if not resolved then
    fk.qWarning("reuse: failed to reuse %s (=>%s)", tostring(reuse_tp), spec._reuse_key)
    stack[spec] = nil
    return nil
  end

  local reuse = resolved --[[@as AIReuseSpec]]
  if reuse._reuse then
    resolved = resolveStrategyReuse(reuse, stack) --[[@as AIStrategy]]
    list[1] = resolved
  end

  stack[spec] = nil
  return resolved
end

--- 解析策略的某个字段的复用
---@param spec AIReuseSpec
---@param tp AIStrategy 类型
---@param key string 字段名
---@param stack any? 避免循环依赖
---@return any
local function resolveFieldReuseOfStrategy(spec, tp, key, stack)
  stack = stack or {}
  if stack[spec] then
    fk.qWarning("AI strategy reuse loop detected (=> %s)", spec._reuse_key)
    return nil
  end
  stack[spec] = true

  local skill = Fk.skills[spec._reuse_key]
  if not skill then return end
  local skel = skill:getSkeleton()
  if not skel then return end

  local resolved

  local list = skel.ai_strategies[tp] or Util.DummyTable
  if not list[1] then return end
  resolved = list[1][key]
  if not resolved then
    fk.qWarning("reuse: failed to reuse %s (=>%s)", tostring(tp), spec._reuse_key)
    stack[spec] = nil
    return nil
  end

  local reuse = resolved --[[@as AIReuseSpec]]
  if type(reuse) == "table" and reuse._reuse then
    resolved = resolveFieldReuseOfStrategy(reuse, tp, key, stack) --[[@as AIStrategy]]
    list[1][key] = resolved
  end

  stack[spec] = nil
  return resolved
end

--- 根据给定的类别、技能名，找到符合目前询问上下文的策略。
---
--- 如果有需要的话，会解析复用的策略/方法等。
---@generic T: AIStrategy
---@param tp T
---@param skill_name string
---@return T?
function SmartAI:findStrategyOfSkill(tp, skill_name)
  if prompt4BaselineEnabled() and PROMPT4_BASELINE_SKILLS[skill_name] then return end
  local skill = Fk.skills[skill_name]
  if not skill then return end
  local skel = skill:getSkeleton()
  if not skel then return end
  local list = skel.ai_strategies[tp] or Util.DummyTable

  local ret
  for i = #list, 1, -1 do
    local tmp = list[i] --[[@as AIReuseSpec]]
    local v
    if tmp._reuse then
      local t = resolveStrategyReuse(tmp)
      if t then
        v = t
        list[i] = t
      else
        table.remove(list, i)
      end
    else
      v = list[i]
    end

    if v and v:matchContext(self) then
      ret = v
      break
    end
  end
  if not ret then return nil end

  if ret._resolved then return ret end

  -- 确保找到的ret没有复用字段，可以直接拿来用了
  for k in pairs(ret) do
    local tmp = ret[k] --[[@as AIReuseSpec]]
    if type(tmp) == "table" and tmp._reuse then
      ret[k] = resolveFieldReuseOfStrategy(tmp, tp, k)
      -- 如果方法变成nil的话 会自动调这个class的默认方法的
    end
  end

  return ret
end

---@type table<string, SkillAI>
fk.ai_skills = {}

---@param key string
---@param spec? SkillAISpec
---@param inherit? string
function SmartAI.static:setSkillAI(key, spec, inherit)
  do return end
end

SmartAI:setSkillAI("__card_skill", {
  choose_targets = function(self, ai)
    -- local targets = ai:getEnabledTargets()
    local logic = AIGameLogic:new(ai)
    local val_func = function(targets)
      logic.benefit = 0
      logic:useCard({
        from = ai.player,
        tos = targets,
        card = ai:getSelectedCard(),
      })
      if self._debug then
        verbose(1, "estimated benefit target_count=%d value=%g", #targets, logic.benefit)
      end
      return logic.benefit
    end
    local best_targets, best_val = nil, -100000
    for targets in self:searchTargetSelections(ai) do
      local val = val_func(targets)
      if (not best_targets) or (best_val < val) then
        best_targets, best_val = targets, val
      end
    end
    return best_targets or {}, best_val
  end,

  think = function(self, ai)
  end,
})

function SmartAI.static:setCardSkillAI(key, spec, key2)
  do return end
end

SmartAI:setCardSkillAI("default_card_skill", {
  on_use = function(self, logic, effect)
    self.skill:onUse(logic, effect)
  end,
  on_effect = function(self, logic, effect)
    self.skill:onEffect(logic, effect)
  end,
})

---@type table<string, TriggerSkillAI>
fk.ai_trigger_skills = {}

function SmartAI.static:setTriggerSkillAI(key, spec)
  do return end
end

function SmartAI:handleAskForUseActiveSkill()
  if not self.handler or not self.handler.skill_name then
    markFallback(self, "malformed_data")
    return ""
  end
  local name = self.handler.skill_name
  self._ai_metric_skill = name

  -- Pindian requests use the generic choose_cards_skill dashboard rather than
  -- a registered skill name.  Select the BOT's highest public hand card here;
  -- opponent cards are never inspected.  Returning the handler's own reply
  -- keeps the existing raw-subcard protocol and validation path intact.
  if name == "choose_cards_skill" and type(self.data) == "table" and
      type(self.data[2]) == "string" and self.data[2]:startsWith("#askForPindian") then
    local best_id, best_number
    for _, id in ipairs(self:getEnabledCards()) do
      local card = safeCardById(id)
      if card and type(card.number) == "number" and
          (not best_id or card.number > best_number or
            (card.number == best_number and id < best_id)) then
        best_id, best_number = id, card.number
      end
    end
    if best_id then
      self:selectCard(best_id, true)
      return self:doOKButton()
    end
    markFallback(self, "no_decision")
    return ""
  end

  local ai
  if self:currentSkill() then
    ai = self:findStrategyOfSkill(AI.ActiveStrategy, self:currentSkill().name)
  end
  if not ai then
    ai = self:findStrategyOfSkill(AI.ActiveStrategy, name)
  end
  if not ai then
    markFallback(self, "no_strategy")
    return ""
  end
  local _dbg_skill = ai.skill and ai.skill.name or "unknown"
  if self._debug then
    verbose(1, "正在询问技能：%s", _dbg_skill)
  end
  local ret, real_val = ai:makeReply(self)
  if self._debug then
    verbose(1, "%s: result_type=%s value_type=%s", _dbg_skill, type(ret), type(real_val))
  end
  return ret, real_val
end

-- 出牌阶段AI的步骤是：
-- 1. 分析手中的手牌、技能按钮以及局势，判断出本次行动意向：
-- 爆发（获得尽量多的牌）、控制（压制敌方状态）、增强（为友方加进攻buff）、进攻（削减敌人生命）、辅助（为友方加防御buff）
-- 2. 将可用方案按优先级排序，根据之前推测出的趋向，某些优先级会被修正
-- 4. 计算优先级最高的3个方案及其收益
--  * 收益值也会被意向值修正
--  * 如果都为负收益则顺延直到有3个正收益选项
--  * 如果依然全部为负收益则与直接点击取消键的收益进行权衡
-- 5. 返回收益最高者
--
-- 推算的相关中间变量都保存在self.mem中，方便各种和ai相关的函数读取。
-- self.mem在每次思考最开始时自动清空。单独开class方便编辑器补全
--====================

---@alias SmartAI.Intention "burst"|"control"|"strengthen"|"attack"|"support"

-- 行动意向评分表保存在mem中。意向评分受可用技能和局势影响，局势判断可以先写死，而技能需要提供自身的功能倾向
--  e.g.刘备有一张无中生有，队友黄月英，方案1开无中并仁德，方案2直接仁德。无中和集智是burst，仁德是support
-- 考虑最佳策略受到局势影响（刘备是否健康，黄月英能否存活到回合，甚至透视无中和集智摸的牌）。简单做法先burst后support，总是还不错的方案
-- 但也可以把仁德收益写得特别高，这样ai会先考虑给牌。取决于编写者的个人喜好

function SmartAI:initIntentionScore()
  if self.mem.intentionScore then return end
  self.mem.intentionScore = {}
end

function SmartAI:handlePlayCard()
  if not self.handler then
    markFallback(self, "malformed_data")
    return ""
  end
  local active_strategy_list = {} ---@type AI.ActiveStrategy[]
  do
    for _, sname in ipairs(self:getEnabledSkills()) do
      local ai = self:findStrategyOfSkill(AI.ActiveStrategy, sname)
      if ai then
        table.insert(active_strategy_list, ai)
      end
    end

    local tmp = {}
    for _, id in ipairs(self:getEnabledCards()) do
      local cd = safeCardById(id)
      if cd and cd.skill then tmp[cd.skill.name] = true end
    end

    for sname in pairs(tmp) do
      local ai = self:findStrategyOfSkill(AI.CardSkillStrategy, sname)
      if ai then
        table.insert(active_strategy_list, ai)
      end
    end
  end

  if self._debug then
    verbose(1, "======== PlayCard evaluation started ========")
  end

  local best_ret, best_val, best_skill, count = "", -1, nil, 0
  local invalidStrategySkills = {}
  if self._debug then
    verbose(1, "目前的决策：直接取消(收益%g)", best_val)
  end
  for _, ai in fk.sorted_pairs(active_strategy_list, function(a) return a.use_priority end) do
    self:selectSkill(ai.skill_name, true)

    local ret, real_val = ai:makeReply(self)
    if self._debug then
      verbose(1, "%s: result_type=%s value_type=%s", ai.skill_name, type(ret), type(real_val))
    end
    real_val = real_val or -100000

    if ret ~= nil and ret ~= "" and type(ret) ~= "table" then
      table.insert(invalidStrategySkills, ai.skill_name)
      ret = ""
      real_val = -100000
    end

    if best_val < real_val then
      if self._debug then
        verbose(1, "candidate replaced value=%g => %g", best_val, real_val)
      end
      best_ret, best_val = ret, real_val
      -- Keep the winning strategy name as bounded metric provenance.  The
      -- serialized PlayCard reply may contain only a numeric card id, so the
      -- base AI cannot recover which skill produced it from the reply alone.
      -- This does not alter the selected reply or any gameplay legality.
      best_skill = ai.skill_name

      --只想20种比较好的决策
      count = count + 1
      if count > 20 then
        break
      end
    end
    self:unSelectAll()
  end

  -- A strategy can exit through the bounded comparison loop above.  Always
  -- clear the temporary UI selection so the next request starts cleanly.
  self:unSelectAll()

  if best_val >= 0 and best_ret ~= "" then
    self._ai_metric_skill = best_skill or self._ai_metric_skill
    recordPrompt4StrategyIssues(self, invalidStrategySkills, true)
    if self._debug then
      verbose(1, "best PlayCard result_type=%s", type(best_ret))
    end
    return best_ret
  end

  recordPrompt4StrategyIssues(self, invalidStrategySkills, false)
  if #invalidStrategySkills > 0 then
    self._ai_metric_skill = invalidStrategySkills[1]
    markFallback(self, "invalid_strategy_reply")
  end

  return ""
end

---------------------------------------------------------------------

-- 其他交互：不涉及面板而是基于弹窗式的交互
-- SkillAI里面每个command给个方法
-- ========================================

function SmartAI:handleAskForCardChosen(data)
  if type(data) ~= "table" then
    markFallback(self, "malformed_data")
    return ""
  end
  local target, card_data, prompt, skill_name = table.unpack(data)
  local reason = type(skill_name) == "string" and skill_name ~= "" and skill_name or
    cardChosenReason(prompt)
  if not reason then
    markFallback(self, "malformed_prompt")
    return ""
  end
  self._ai_metric_skill = reason
  -- The current strategy registry names this request type ChooseCardStrategy;
  -- accept the historical alias when a runtime provides one.
  local card_strategy_type = AI.CardChosenStrategy or AI.ChooseCardStrategy
  local ai = self:findStrategyOfSkill(card_strategy_type, reason)
  if ai then
    if self._debug then
      verbose(1, "asking skill=%s", ai.skill_name)
    end
    local ret, real_val = ai:makeReply(self)
    if self._debug then
      verbose(1, "%s: result_type=%s value_type=%s", ai.skill_name, type(ret), type(real_val))
    end
    return ret
  end
  markFallback(self, "no_strategy")
  return ""
end

-- View-as skills are exposed as SkillButton choices on both AskForUseCard and
-- AskForResponseCard.  The old legacy `fk.ai_skills` table is intentionally
-- empty in the current LTK path, so route registered ActiveStrategy objects
-- through the real request handler instead of falling back to the first raw
-- card.  Keep the candidate set to enabled server-provided skill buttons and
-- replay the winning selection through the handler before returning it.
local function tryActiveSkillStrategies(self, explicit_names)
  -- Some request tests and legacy integrations intentionally provide a
  -- lightweight handler without a dashboard scene.  There is no safe way to
  -- enumerate skill buttons in that shape; let the existing physical-card
  -- fallback handle it instead of turning a valid response into an AI
  -- exception.
  if not self.handler or not self.handler.scene or
      type(self.handler.scene.getAllItems) ~= "function" then
    return nil
  end
  local names = {}
  if type(explicit_names) == "table" then
    for _, name in ipairs(explicit_names) do
      if type(name) == "string" and name ~= "" then table.insertIfNeed(names, name) end
    end
  else
    for _, name in ipairs(self:getEnabledSkills()) do
      table.insertIfNeed(names, name)
    end
  end
  if self.handler and type(self.handler.skill_name) == "string" and self.handler.skill_name ~= "" then
    table.insertIfNeed(names, self.handler.skill_name)
  end
  table.sort(names)

  local best_reply, best_value, best_skill = nil, -100000, nil
  for _, name in ipairs(names) do
    local strategy = self:findStrategyOfSkill(AI.ActiveStrategy, name)
    if strategy then
      self:unSelectAll()
      if not self.handler.skill_name or self.handler.skill_name ~= name then
        self:selectSkill(name, true)
      end
      local reply, value = strategy:makeReply(self)
      value = type(value) == "number" and value or -100000
      if type(reply) == "table" and type(reply.card) == "table" and
          type(reply.card.subcards) == "table" and value > best_value then
        best_reply, best_value, best_skill = reply, value, name
      end
      self:unSelectAll()
    end
  end

  if not best_reply then return nil end

  -- Recreate the chosen handler state using its normal update methods.  This
  -- keeps feasibility/target legality owned by the request handler rather
  -- than trusting the strategy's serialized reply alone.
  self:selectSkill(best_skill, true)
  for _, id in ipairs(best_reply.card.subcards or Util.DummyTable) do
    self:selectCard(id, true)
  end
  for _, id in ipairs(best_reply.targets or Util.DummyTable) do
    local target = safePlayerById(self.room, id)
    if target then self:selectTarget(target, true) end
  end
  return best_reply
end

function SmartAI:handleAskForSkillInvoke(data)
  if type(data) ~= "table" or type(data[1]) ~= "string" then
    markFallback(self, "malformed_data")
    return ""
  end
  local skillName, prompt = data[1], data[2]
  self._ai_metric_skill = skillName
  local ai = self:findStrategyOfSkill(AI.InvokeStrategy, skillName)
  if ai then
    if self._debug then
      verbose(1, "asking skill=%s", skillName)
    end
    local ret = ai:makeReply(self)
    if self._debug then
      verbose(1, "%s: result_type=%s", skillName, type(ret))
    end
    return ret == true and "1" or ""
  else
    markFallback(self, "no_strategy")
    return ""
  end
end

function SmartAI:handleAskForChoice(data)
  if type(data) ~= "table" then
    markFallback(self, "malformed_data")
    return ""
  end
  local choices, allChoices, skillName, prompt = table.unpack(data)
  if type(choices) ~= "table" or #choices == 0 or type(skillName) ~= "string" then
    markFallback(self, "malformed_data")
    return ""
  end
  self._ai_metric_skill = skillName
  local ai = self:findStrategyOfSkill(AI.ChoiceStrategy, skillName)
  if ai then
    if self._debug then
      verbose(1, "asking skill=%s choice_count=%d", ai.skill_name, #choices)
    end
    local ret, real_val = ai:makeReply(self)
    if self._debug then
      verbose(1, "%s: result_type=%s value_type=%s", ai.skill_name, type(ret), type(real_val))
    end
    if type(ret) == "string" and table.contains(choices, ret) then
      return ret
    end
    markFallback(self, ret == nil and "no_decision" or "invalid_strategy_reply")
    return choices[1]
  else
    markFallback(self, "no_strategy")
    return choices[1]
  end
end

-- Multi-choice requests use a different wire shape from AskForChoice.  Keep
-- single-choice skill strategies where applicable, then make a conservative
-- selection from the exact options supplied by the server.
local function replyToSelectionList(ai, data)
  if type(data) ~= "table" or type(data[1]) ~= "table" or
    type(data[3]) ~= "table" then
    markFallback(ai, "malformed_data")
    return ""
  end
  local choices, limits = data[1], data[3]
  local min_num, max_num = limits[1], limits[2]
  if type(min_num) ~= "number" or min_num % 1 ~= 0 or min_num < 0 or
    type(max_num) ~= "number" or max_num % 1 ~= 0 or max_num < min_num then
    markFallback(ai, "malformed_data")
    return ""
  end

  if min_num == 1 and max_num == 1 and type(data[5]) == "string" and
    data[5] ~= "" then
    local strategy = ai:findStrategyOfSkill(AI.ChoiceStrategy, data[5])
    if strategy then
      local candidate = strategy:makeReply(ai)
      if type(candidate) == "table" and #candidate == 1 then candidate = candidate[1] end
      if type(candidate) == "string" then
        for _, choice in ipairs(choices) do
          if candidate == choice then return { candidate } end
        end
      end
      markFallback(ai, "invalid_strategy_reply")
    end
  end

  local selected, seen = {}, {}
  for _, choice in ipairs(choices) do
    if type(choice) ~= "string" then
      markFallback(ai, "malformed_data")
      return ""
    end
    if not seen[choice] then
      seen[choice] = true
      if #selected < min_num then table.insert(selected, choice) end
    end
  end
  if #selected < min_num then
    if data[4] == true then return {} end
    markFallback(ai, "no_decision")
    return ""
  end
  return selected
end

function SmartAI:handleAskForChoices(data)
  return replyToSelectionList(self, data)
end

function SmartAI:handleAskForOptions(data)
  return replyToSelectionList(self, data)
end

-- AG cards are visible to all players.  Use existing card evaluations when
-- available, otherwise keep the server's order as a deterministic baseline.
function SmartAI:handleAskForAG(data)
  if type(data) ~= "table" or type(data[1]) ~= "table" then
    markFallback(self, "malformed_data")
    return ""
  end
  local best_id, best_value
  for _, id in ipairs(data[1]) do
    if type(id) ~= "number" or id % 1 ~= 0 then
      markFallback(self, "malformed_data")
      return ""
    end
    local ok, value = pcall(self.getCardValue, self, id, "use_value")
    if not ok or type(value) ~= "number" or value ~= value or
      value == math.huge or value == -math.huge then value = 0 end
    if not best_id or value > best_value then
      best_id, best_value = id, value
    end
  end
  return best_id or ""
end

-- Each position is paired with a card by its index in the native payload.
-- The base validator checks that pairing again before handing it to Room.
function SmartAI:handleAskForMoveCardInBoard(data)
  if type(data) ~= "table" or type(data.cards) ~= "table" or
    type(data.cardsPosition) ~= "table" or
    #data.cards ~= #data.cardsPosition then
    markFallback(self, "malformed_data")
    return ""
  end
  for i, id in ipairs(data.cards) do
    local pos = data.cardsPosition[i]
    if type(id) == "number" and id % 1 == 0 and (pos == 0 or pos == 1) then
      return { cardId = id, pos = pos }
    end
  end
  return ""
end

-- Room supplies the allowed cards and a separate disabled list.  Without a
-- filter skeleton, a minimal selection with the server's default choice is
-- equivalent to Room's own fallback.  A filter skeleton can impose custom
-- combinations, so leave those requests to Room until a skill-aware strategy
-- can prove feasibility.
function SmartAI:handleAskForCardsAndChoice(data)
  if type(data) ~= "table" or type(data.cards) ~= "table" or
    type(data.choices) ~= "table" or type(data.disabled) ~= "table" or
    (data.filter_skel ~= nil and data.filter_skel ~= "") then
    markFallback(self, "no_strategy")
    return ""
  end
  local min_num, max_num = data.min, data.max
  if type(min_num) ~= "number" or min_num % 1 ~= 0 or min_num < 0 or
    type(max_num) ~= "number" or max_num % 1 ~= 0 or max_num < min_num then
    markFallback(self, "malformed_data")
    return ""
  end
  local choice = data.choices[1]
  if type(choice) ~= "string" then
    markFallback(self, "no_decision")
    return ""
  end

  -- 尚义's second step has already revealed the target's hand to this seat.
  -- Choose the most valuable legal black card when the optional discard is
  -- available; do not resolve any other hidden hand or alter the server rule.
  if type(data.prompt) == "string" and data.prompt:startsWith("#shangyi_card") then
    local best_id, best_value
    if max_num > 0 then
      for _, id in ipairs(data.cards) do
        if type(id) == "number" and id % 1 == 0 and not table.contains(data.disabled, id) then
          local value = self:getCardValue(id, "keep_value")
          if not best_id or value > best_value or (value == best_value and id < best_id) then
            best_id, best_value = id, value
          end
        end
      end
    end
    return { cards = best_id and { best_id } or {}, choice = choice }
  end

  local cards, seen = {}, {}
  for _, id in ipairs(data.cards) do
    if type(id) == "number" and id % 1 == 0 and not seen[id] then
      seen[id] = true
      if not table.contains(data.disabled, id) and #cards < min_num then
        table.insert(cards, id)
      end
    end
  end
  if #cards < min_num then
    markFallback(self, "no_decision")
    return ""
  end
  return { cards = cards, choice = choice }
end

-- Response-card requests can select a ViewAs skill (急救/龙胆/武圣 and
-- similar) through the same dashboard handler.  Prefer a legal strategy
-- reply; retain TrustAI's conservative physical-card fallback for skills that
-- have no bounded strategy yet.
function SmartAI:handleAskForResponseCard(data)
  if type(data) ~= "table" or type(data[2]) ~= "string" then
    markFallback(self, "malformed_data")
    return ""
  end
  local reply = tryActiveSkillStrategies(self)
  if reply then return reply end
  return TrustAI.handleAskForResponseCard(self, data)
end

function SmartAI:handleAskForUseCard(data)
  if type(data) ~= "table" or type(data[2]) ~= "string" then
    markFallback(self, "malformed_data")
    return ""
  end
  local card_ids = self:getEnabledCards()
  local skill_name, pattern, prompt = data[1], data[2], data[3]
  if pattern == "jink" then
    -- A native BOT may hold non-Jink cards before its reserved Jink.  Filter
    -- through the server-provided pattern before selecting; trying the first
    -- hand card made a legal Jink response look like a no-decision fallback.
    for _, id in ipairs(self:getEnabledCards(pattern)) do
      self:selectCard(id, true) -- 默认按下卡牌后直接可确定 懒得管了
      return self:doOKButton()
    end
  elseif pattern == "nullification" then
    local from, to, card
    local extra_data = type(data[5]) == "table" and data[5] or {}
    if extra_data.effectFrom then
      from = safePlayerById(self.room, extra_data.effectFrom)
      if extra_data.effectCardId then
        card = safeCardById(extra_data.effectCardId)
      end
    elseif extra_data.effectCardId then
      card = safeCardById(extra_data.effectCardId)
    end
    to = extra_data.effectTo or nullificationTargetId(prompt)
    if to then
      to = safePlayerById(self.room, to)
    end
    if not to then
      markFallback(self, "malformed_prompt")
      return ""
    end
    local should_use = false
    if from and to and card then
      local benefit = self:getBenefitOfEvents(function(logic)
        logic:useCard{
          from = from,
          tos = { to },
          card = card,
        }
      end)
      should_use = benefit < 0
    else
      should_use = to and self:shouldProtect(to) or false
    end
    if should_use then
      local skill_reply = tryActiveSkillStrategies(self)
      if skill_reply then return skill_reply end
      for _, id in ipairs(card_ids) do
        self:selectCard(id, true)
        return self:doOKButton()
      end
    end
    return ""
  elseif pattern:startsWith("peach") then
    local to = type(prompt) == "string" and prompt:startsWith("#AskForPeachesSelf")
      and self.player.id or peachTargetId(prompt)
    if to then
      to = safePlayerById(self.room, to)
      if to and self:shouldProtect(to) then
        local skill_reply = tryActiveSkillStrategies(self)
        if skill_reply then return skill_reply end
        for _, cd in ipairs(card_ids) do
          self:selectCard(cd, true)
          return self:doOKButton()
        end
      end
    end
    return ""
  end

  -- Explicit AskForUseCard requests (not only PlayCard) can expose ViewAs
  -- skills such as 武圣/乱击/火计.  Their registered strategies perform the
  -- target and resource comparison; physical-card candidates below retain
  -- precedence when they already have a dedicated card AI.
  local viewas_reply = tryActiveSkillStrategies(self)
  if viewas_reply then return viewas_reply end

  local skill_ai_list = {}
  for _, id in ipairs(card_ids) do
    local cd = safeCardById(id)
    if cd and cd.skill then
      local ai = fk.ai_skills[cd.skill.name]
      if ai then
        table.insertIfNeed(skill_ai_list, ai)
      end
    end
  end
  for _, sname in ipairs(self:getEnabledSkills()) do
    local ai = fk.ai_skills[sname]
    if ai then
      table.insertIfNeed(skill_ai_list, ai)
    end
  end
  if self._debug then
    verbose(1, "======== use-card evaluation started candidates=%d ========", #skill_ai_list)
  end

  local value_func = function(ai)
    if not ai then return -500 end
    local val = ai:getEstimatedBenefit(self)
    return val or 0
  end

  local best_ret, best_val = "", -100000
  for _, ai, val in fk.sorted_pairs(skill_ai_list, value_func) do
    if self._debug then
      verbose(1, "[*] 考虑 %s (预估收益%g)", ai.skill.name, val)
    end
    self:selectSkill(ai.skill.name, true)
    local ret, real_val = ai:think(self)
    if self._debug then
      verbose(1, "%s: result_type=%s value_type=%s", ai.skill.name, type(ret), type(real_val))
    end
    real_val = real_val or -100000
    if ret ~= nil and ret ~= "" and type(ret) ~= "table" then
      markFallback(self, "invalid_strategy_reply")
      ret = ""
      real_val = -100000
    end
    -- if ret and ret ~= "" then return ret end
    if best_val < real_val then
      if self._debug then
        verbose(1, "candidate replaced value=%g => %g", best_val, real_val)
      end
      best_ret, best_val = ret, real_val
    end
    self:unSelectAll()
  end
  if self._debug then
    verbose(1, "best use-card result_type=%s", type(best_ret))
  end
  if best_ret and best_ret ~= "" then return best_ret end
  -- A parent skill can ask for a normal Slash (or another physical card) in
  -- an AskForUseCard request.  The skill strategy list is intentionally about
  -- ViewAs/active strategies, so finish with the native physical-card path
  -- before classifying the request as no_strategy.
  local physical_reply = tryPhysicalCardUse(self, pattern, card_ids)
  if physical_reply then return physical_reply end
  if #skill_ai_list == 0 then markFallback(self, "no_strategy") end
  return ""
end

-- 敌友判断相关。
-- 目前才开始，做个明身份打牌的就行了。
--========================================

---@param target ServerPlayer
function SmartAI:isFriend(target)
  if not self:isHegemonyAI() then return self.player:isFriend(target) end
  return self:getFactionRelation(target).state == "friend"
end

---@param target ServerPlayer
function SmartAI:isEnemy(target)
  if not self:isHegemonyAI() then return not self.player:isFriend(target) end
  return self:getFactionRelation(target).state == "enemy"
end

function SmartAI:isHegemonyAI()
  return self.room and type(self.room.getSettings) == "function" and
    self.room:getSettings("gameMode") == "new_heg_mode"
end

--- Rule-backed ternary state plus an explicitly uncertain, seat-local estimate.
function SmartAI:getFactionRelation(target)
  if not self:isHegemonyAI() then
    local friend = target == self.player or self.player:isFriend(target)
    return { state = friend and "friend" or "enemy", confidence = 1,
      probabilities = {}, attitude = friend and 1 or -1 }
  end
  return self.factionInference:relation(target)
end

--- Positive means helping a player is useful; negative means harming them is.
function SmartAI:getFactionAttitude(target)
  return self:getFactionRelation(target).attitude
end

--- Conserves rescue and nullification cards for confirmed or well-supported allies.
function SmartAI:shouldProtect(target)
  local relation = self:getFactionRelation(target)
  if relation.state == "friend" then return true end
  if relation.state ~= "unknown" or relation.confidence < 0.6 then return false end
  local mine = self.player.kingdom
  if mine == "unknown" and type(self.player.getMark) == "function" then
    mine = self.player:getMark("__heg_kingdom")
  end
  return mine and (relation.probabilities[mine] or 0) >= 0.78 or false
end

-- 排序相关函数。
-- 众所周知AI要排序，再选出尽可能最佳的选项。
-- 这里提供了常见的完整排序和效率更高的不完整排序。
--=================================================

-- sorted_pairs 见 core/util.lua

---@param tab ServerPlayer[]
---@param key "hp"|"handcard"|"handcard_defense"|"value"|"taunt"|"defense"|"threat"
---@param reverse boolean?
function SmartAI:sortPlayers(tab, key, reverse)
end

---@param card integer|Card
---@param key "keep_value"|"use_value"|nil
---@return number
function SmartAI:getCardValue(card, key)
  if type(card) == "number" then
    card = safeCardById(card)
  end
  ---@cast card -integer

  if not card or not card.skill then return 0 end

  local strategy = self:findStrategyOfSkill(AI.CardSkillStrategy, card.skill.name)
  local ret = 0
  if strategy then
    -- TODO: 可能可以是function
    ret = strategy.keep_value or 0
  end

  -- TODO: 可能可以类似状态技一样给Room挂点状态技性质策略
  -- TODO: 这样那些策略会影响某些卡的keep value

  return ret
end

-- 将卡牌id数组按照某种估值从小到大原地排序
---@param ids integer[]
---@param key "keep_value"|"use_value"|"use_priority"
---@param reverse boolean? 是否反过来（从大到小）排序
function SmartAI:sortCards(ids, key, reverse)
  -- value_tab是必须的，因为table.sort每轮比较时都会调用一次fun(a,b)
  -- 太阳神卡慢的点之一就是没有提前计算出结果
  local value_tab = {}
  for _, id in ipairs(ids) do
    value_tab[id] = self:getCardValue(id)
  end

  table.sort(ids, function(a, b)
    local va, vb = value_tab[a], value_tab[b]
    if reverse then
      return va > vb
    else
      return va < vb
    end
  end)
end

-- 基于事件的收益推理；内置事件
--=================================================

--- 传一个函数，函数里面模拟操作，返回一系列模拟操作后的收益
---@param fn fun(logic: AIGameLogic) 此函数放置想要的事件
function SmartAI:getBenefitOfEvents(fn)
  local logic = AIGameLogic:new(self)
  fn(logic)
  return logic.benefit
end

---------------------------------------------------------------------

-- 封装一些简单策略
-- ========================================

---@class AIAskToChooseCardsParams
---@field cards integer[] @ 被选择的牌
---@field skill_name string @ 请求发动的技能名
---@field data table @ 用moveCardTo的参数表示这些牌即将被用来做什么操作

--- 选牌
---@param params AIAskToChooseCardsParams @ 各种变量
---@return integer[], integer @ 返回本次选牌收益最大的一种情况，选择的卡牌和收益
function SmartAI:askToChooseCards(params)
  local skill_name, data = params.skill_name, params.data
  data.min = data.min or 1
  data.max = data.max or data.min
  local cards = table.simpleClone(params.cards)
  local ret, benefit = { }, -100000
  for _ = data.max, 1, -1 do
    local tmp_id, tmp_benefit = -1, -100000
    for _, id in ipairs(cards) do
      local v = self:getBenefitOfEvents(function(logic)
        logic:moveCardTo(id, data.toArea, data.target, data.reason, skill_name, nil, false, data.proposer)
      end)
      if v > tmp_benefit then
        tmp_id, tmp_benefit = id, v
      end
    end
    table.insertIfNeed(ret, tmp_id)
    benefit = benefit + tmp_benefit
    table.removeOne(cards, tmp_id)
  end
  return ret, benefit
end

---@class AIAskToChoosePlayersParams
---@field benefit_func function @ 计算选这些角色收益的函数
---@field basic_benefit integer? @ 基础收益，默认为0（如“突袭”的基础收益是放弃摸牌）

--- 选角色
---@param params AIAskToChoosePlayersParams @ 各种变量
---@return ServerPlayer[], integer @ 返回本次选角色收益最大的一种情况，选择的角色和收益
function SmartAI:askToChoosePlayers(params)
  params.skill_name = params.skill_name or ""
  if params.cancelable then
    params.min_num = 0
  else
    params.min_num = params.min_num or 1
  end
  params.max_num = params.max_num or params.min_num
  local players = table.simpleClone(params.targets or self:getEnabledTargets())
  local benefits = table.map(players, function(p)
    return { p, self:getBenefitOfEvents(function(logic)
      params.benefit_func(logic, p)
    end) }
  end)
  local total_benefit = params.basic_benefit or 0
  local targets = {}
  table.sort(benefits, function(a, b) return a[2] > b[2] end)
  for i, benefit in ipairs(benefits) do
    local p, val = table.unpack(benefit)
    if val < 0 and i > params.min_num then break end
    table.insert(targets, p)
    total_benefit = total_benefit + val
    if i == params.max_num then break end
  end
  if #targets == 0 then return {}, 0 end
  return targets, total_benefit
end

-- 局势分析
--========================================

-- AI需要“帮助”某玩家的程度
---@param target ServerPlayer
---@param key string?
---@return number
function SmartAI:needHelp(target, key)
  local keys = { "hp", "h", "e" }
  if key then
    keys = string.split(key, "|")
  end
  local n = 0
  if table.contains(keys, "hp") then
    n = n + 200 * (target.maxHp - target.hp - target.shield)
  end
  if table.contains(keys, "h") then
    if self:isHegemonyAI() and target ~= self.player then
      -- Opponents' hand counts are public; their card IDs are private.
      -- Use a neutral card-count estimate for unrevealed hand contents.
      if type(target.getHandcardNum) == "function" then
        n = n + target:getHandcardNum() * 25
      end
    else
      for _, id in ipairs(target:getCardIds("h")) do
        local valueAI = self:isHegemonyAI() and self or target.ai
        n = n + valueAI:getCardValue(id)
      end
    end
  end
  if table.contains(keys, "e") then
    for _, id in ipairs(target:getCardIds("e")) do
      local valueAI = self:isHegemonyAI() and self or target.ai
      n = n + valueAI:getCardValue(id)
    end
  end
  return n * self:getFactionAttitude(target)
end

return SmartAI
