-- SPDX-License-Identifier: GPL-3.0-or-later

-- AI base class.
-- Do nothing.

---@class AI: Base.AI
---@field public room Room
---@field public player ServerPlayer
---@field public handler ReqActiveSkill
local AI = Fk.Base.AI:subclass("AI")

local DASHBOARD_COMMANDS = {
  AskForUseActiveSkill = true,
  AskForResponseCard = true,
  AskForUseCard = true,
  PlayCard = true,
}

function AI:initialize(player)
  Fk.Base.AI.initialize(self, player)
end

-- activeSkill, responseCard, useCard, playCard 四巨头专属
function AI:isInDashboard()
  local command = type(self.command) == "string" and self.command or nil
  local handler_class = command and DASHBOARD_COMMANDS[command] and
    self.room and self.room.request_handlers and self.room.request_handlers[command]
  if not (self.handler and handler_class and self.handler:isInstanceOf(handler_class)) then
    fk.qWarning("请检查是否在AI中调用了专属于dashboard操作的一系列函数")
    return false
  end
  return true
end

function AI:getPrompt()
  local handler = self.handler
  if not handler then return "" end
  return handler.prompt
end

--- 返回当前手牌区域内（包含展开的pile）中所有可选且未选中的卡牌 返回ids
---@param pattern string? 可以带一个过滤条件
---@return integer[]
function AI:getEnabledCards(pattern)
  if not self:isInDashboard() then return Util.DummyTable end

  local ret = {}
  for cid, item in pairs(self.handler.scene:getAllItems("CardItem")) do
    if item.enabled and not item.selected then
      if (not pattern) or Exppattern:Parse(pattern):match(Fk:getCardById(cid)) then
        table.insert(ret, cid)
      end
    end
  end
  return ret
end

--- 返回当前所有可选并且还未选中的角色
---@return ServerPlayer[]
function AI:getEnabledTargets()
  if not self:isInDashboard() then return Util.DummyTable end
  local room = self.room

  local ret = {}
  for pid, item in pairs(self.handler.scene:getAllItems("Photo")) do
    if item.enabled and not item.selected then
      table.insert(ret, room:getPlayerById(pid))
    end
  end
  return ret
end

function AI:hasEnabledTarget()
  if not self:isInDashboard() then return false end
  local room = self.room

  for _, item in pairs(self.handler.scene:getAllItems("Photo")) do
    if item.enabled and not item.selected then
      return true
    end
  end
  return false
end

--- 获取技能面板中所有可以按下的技能按钮
---@return string[]

--- 获取技能面板中所有可以按下的技能按钮
---@return string[]
function AI:getEnabledSkills()
  if not self:isInDashboard() then return Util.DummyTable end

  local ret = {}
  for name, item in pairs(self.handler.scene:getAllItems("SkillButton")) do
    if item.enabled and not item.selected then
      table.insert(ret, name)
    end
  end
  return ret
end

---@return integer[]
function AI:getSelectedCards()
  if not self:isInDashboard() then return Util.DummyTable end
  return table.simpleClone(self.handler.pendings)
end

---@return Card?
function AI:getSelectedCard()
  if not self:isInDashboard() then return nil end
  local handler = self.handler
  if handler.selected_card then return handler.selected_card end
  if not handler.skill_name then return end
  local skill = Fk.skills[handler.skill_name]
  if not skill:isInstanceOf(ViewAsSkill) then return end
  return skill:viewAs(self.player, handler.pendings)
end

---@return ServerPlayer[]
function AI:getSelectedTargets()
  if not self:isInDashboard() then return Util.DummyTable end
  return table.map(self.handler.selected_targets, function(pid)
    return self.room:getPlayerById(pid)
  end)
end

function AI:getSelectedSkill()
  if not self:isInDashboard() then return nil end
  return self.handler.skill_name
end

function AI:selectCard(cid, selected)
  if not self:isInDashboard() then return end
  self.handler:update("CardItem", cid, "click", { selected = selected })
  if self._debug then
    verbose(0, "[UI] card selection changed selected=%s", tostring(selected))
  end
end

---@param player ServerPlayer
function AI:selectTarget(player, selected)
  if not self:isInDashboard() then return end
  self.handler:update("Photo", player.id, "click", { selected = selected })

  if self._debug then
    verbose(0, "[UI] target selection changed selected=%s", tostring(selected))
  end
end

function AI:selectSkill(skill_name, selected)
  if not self:isInDashboard() then return end
  local items = self.handler.scene.items
  if not items["SkillButton"] then return end
  if not items["SkillButton"][skill_name] then return end
  self.handler:update("SkillButton", skill_name, "click", { selected = selected })

  if self._debug then
    verbose(0, "[UI] 已%s选择技能%s", selected and "" or "取消", skill_name)
  end
end

function AI:unSelectAllCards()
  for _, id in ipairs(self:getSelectedCards()) do
    self:selectCard(id, false)
  end
end

function AI:unSelectAllTargets()
  for _, p in ipairs(self:getSelectedTargets()) do
    self:selectTarget(p, false)
  end
end

function AI:unSelectSkill()
  local skill = self:getSelectedSkill()
  if not skill then return end
  self:selectSkill(skill, false)
end

function AI:unSelectAll()
  self:unSelectSkill()
  self:unSelectAllCards()
  self:unSelectAllTargets()
end

function AI:okButtonEnabled()
  if not self:isInDashboard() then return false end
  return self.handler:feasible()
end

function AI:isDeadend()
  if not self:isInDashboard() then return true end
  return (not self:okButtonEnabled()) and #self:getEnabledCards() == 0
    and #self:getEnabledTargets() == 0
end

function AI:doOKButton()
  if not self:isInDashboard() then return "" end
  if not self:okButtonEnabled() then return "" end
  local reply = self.handler:doOKButton()
  if reply ~= nil then
    -- Base.AI uses identity for replies produced by the legality-checked
    -- dashboard.  Strategies that construct a reply themselves are still
    -- checked by validateReply below.
    self._last_ai_reply = reply
  end
  return reply or ""
end

--- Validate a dashboard reply before Request stores it as the result.
--- The handler's own feasibility rules remain the source of truth; this
--- method only replays the candidate without sending a second UI reply.
function AI:validateReply(command, _, reply)
  if not DASHBOARD_COMMANDS[command] then return true end
  if type(reply) ~= "table" then return false, "invalid_reply" end
  if self._last_ai_reply == reply then return true end

  local function reject(detail)
    self._ai_validation_detail = detail
    return false, "illegal_reply"
  end

  local handler = self.handler
  if not handler or type(handler.feasible) ~= "function" then
    return reject("missing_handler")
  end

  local card = reply.card
  local card_object
  if type(card) == "number" then
    local ok, value = pcall(Fk.getCardById, Fk, card)
    if not ok or not value then return reject("card_lookup_failed") end
    card_object = value
  elseif type(card) == "table" then
    local raw_choose_cards = handler.skill_name == "choose_cards_skill" and card.skill == nil
    if (not raw_choose_cards and type(card.skill) ~= "string") or type(card.subcards) ~= "table" then
      return false, "invalid_reply"
    end
    if not raw_choose_cards and not Fk.skills[card.skill] then return reject("skill_missing") end
  else
    return false, "invalid_reply"
  end

  if reply.special_skill ~= nil and not Fk.skills[reply.special_skill] then
    return reject("special_skill_missing")
  end

  local snapshot = {
    skill_name = handler.skill_name,
    pendings = handler.pendings,
    selected_targets = handler.selected_targets,
    selected_card = handler.selected_card,
    sub_selection_flag = handler.sub_selection_flag,
    selected_buffer = handler.selected_buffer,
    sub_cards = handler.sub_cards,
    sub_pendings = handler.sub_pendings,
  }

  local interaction_skill
  local interaction_data
  local ok, feasible = pcall(function()
    handler.sub_selection_flag = false
    handler.selected_buffer = nil
    handler.selected_targets = table.simpleClone(reply.targets)
    if type(card) == "table" then
      handler.skill_name = raw_choose_cards and snapshot.skill_name or card.skill
      handler.pendings = table.simpleClone(card.subcards)
      handler.selected_card = nil
    else
      handler.skill_name = reply.special_skill
      handler.pendings = reply.special_skill and { card } or {}
      handler.selected_card = card_object
    end

    local skill = handler.skill_name and Fk.skills[handler.skill_name]
    if skill and skill.interaction and reply.interaction_data ~= nil then
      interaction_skill = skill
      interaction_data = skill.interaction.data
      skill.interaction.data = reply.interaction_data
    end
    return handler:feasible()
  end)

  if interaction_skill then
    interaction_skill.interaction.data = interaction_data
  end
  handler.skill_name = snapshot.skill_name
  handler.pendings = snapshot.pendings
  handler.selected_targets = snapshot.selected_targets
  handler.selected_card = snapshot.selected_card
  handler.sub_selection_flag = snapshot.sub_selection_flag
  handler.selected_buffer = snapshot.selected_buffer
  handler.sub_cards = snapshot.sub_cards
  handler.sub_pendings = snapshot.sub_pendings

  if not ok then return reject("feasibility_exception") end
  if not feasible then return reject("feasibility_rejected") end
  return true
end

---@return Skill?
function AI:currentSkill()
  local room = self.room
  if room.current_cost_skill then return room.current_cost_skill end
  local sname = room.logic:getCurrentSkillName()
  if sname then
    return Fk.skills[sname]
  end
end

function AI:makeReply()
  local is_active = self.command == "AskForUseActiveSkill"
  local skill
  local previous_extra_data
  if is_active and type(self.data) == "table" then
    skill = Fk.skills[self.data[1]]
    if skill then
      previous_extra_data = skill._extra_data
      skill._extra_data = self.data[4]
    end
  end

  local ret = Fk.Base.AI.makeReply(self)

  if skill then
    skill._extra_data = previous_extra_data or Util.DummyTable
  end

  return ret
end

return AI
