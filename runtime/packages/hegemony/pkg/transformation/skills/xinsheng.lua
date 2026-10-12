local U = require "packages.utility.utility"

---@param player ServerPlayer
---@param skillName string
local addFangkeSkill = function(player, skillName)
  local room = player.room
  local skill = Fk.skills[skillName]
  if not skill or #skill:getSkeleton().tags > 0 or player:hasSkill(skill) then
    return
  end
  room:addTableMark(player, "ld__xing_skills", skillName)
  player:addFakeSkill(skill)
  player:prelightSkill(skill, true)
end

---@param player ServerPlayer
---@param skillName string
local removeFangkeSkill = function(player, skillName)
  local room = player.room
  local skill = Fk.skills[skillName]
  room:removeTableMark(player, "ld__xing_skills", skillName)
  player:loseFakeSkill(skill)
end

---@param player ServerPlayer
---@param general General
---@param addSkill? boolean
local function addFangke(player, general, addSkill)
  local room = player.room
  local glist = player:getMark("@&ld__xing")
  if glist == 0 then glist = {} end
  table.insertIfNeed(glist, general.name)
  room:setPlayerMark(player, "@&ld__xing", glist)

  if not addSkill then return end
  for _, s in ipairs(general.skills) do
    addFangkeSkill(player, s.name)
  end
  for _, sname in ipairs(general.other_skills) do
    addFangkeSkill(player, sname)
  end
end

---@param player ServerPlayer
---@param general string
local function removeFangke(player, general)
  local room = player.room
  local glist = player:getTableMark("@&ld__xing")
  if table.removeOne(glist, general) then
    room:setPlayerMark(player, "@&ld__xing", #glist == 0 and 0 or glist)
    for _, sname in ipairs(Fk.generals[general]:getSkillNameList()) do
      removeFangkeSkill(player, sname)
    end
  end
end

local xinsheng = fk.CreateSkill{
  name = "ld__xinsheng",
}
xinsheng:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, _)
    if not (target == player and player:hasSkill(xinsheng.name)) then return end
    return player.phase == Player.Start
  end,
  on_use = function(self, event, _, player, _)
    local room = player.room
    local generals = {}
    local m = player:getMark("@&ld__xing")
    if m == 0 or #m < 2 then
      local all_xing = room:getNGenerals(5)
      generals = U.askToChooseGeneralsAndChoice(player, {
        skill_name = xinsheng.name,
        generals = all_xing,
        prompt = "#ld__xinshen_xing2",
        min_num = 2,
        max_num = 2,
      })
    else
      local choices = player:getMark("@&ld__xing")
      local result = U.askToChooseGeneralsAndChoice(player, {
        skill_name = xinsheng.name,
        generals = choices,
        prompt = "#ld__xinshen_xing_recast",
        max_num = 1,
      })
      removeFangke(player, result[1])
      generals = room:getNGenerals(1)
    end
    table.forEach(generals, function(g) addFangke(player, Fk.generals[g], true) end)
  end,
})
xinsheng:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, _)
    return target == player and player:hasSkill(xinsheng.name)
  end,
  on_use = function(self, event, _, player, _)
    local room = player.room
    local generals = room:getNGenerals(1)
    table.forEach(generals, function(g) addFangke(player, Fk.generals[g], true) end)
  end,
})
xinsheng:addLoseEffect(function (self, player, is_death)
  local record = table.simpleClone(player:getTableMark("@&ld__xing"))
  for _, s in ipairs(record) do
    removeFangke(player, s)
  end
end)

Fk:loadTranslationTable{
  ["ld__xinsheng"] = "新生",
  [":ld__xinsheng"] = "准备阶段，若你的“形”：少于两张，你可以观看武将牌堆中的随机五张武将牌，" ..
    "选择其中的两张置于你的武将牌上（称为“形”）；不少于两张，你可以将一张“形”置入武将牌堆，" ..
    "然后随机将武将牌堆中的一张武将牌置于你的武将牌上（称为“形”）。" ..
    "当你受到伤害后，你可以随机将武将牌堆中的一张武将牌置于你的武将牌上（称为“形”）。",

  ["@&ld__xing"] = "形",

  ["#ld__xinshen_xing1"] = "新生：选择一张武将牌置于你的武将牌上，称为“形”",
  ["#ld__xinshen_xing2"] = "新生：选择两张武将牌置于你的武将牌上，称为“形”",
  ["#ld__xinshen_xing_recast"] = "新生：移去一张“形”，然后随机将一张武将牌置于你的武将牌上，称为“形”",

  ["$ld__xinsheng1"] = "大成若缺，损益无妨。",
  ["$ld__xinsheng2"] = "大盈若冲，心神自现。",
}

return xinsheng
