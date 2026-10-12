
local huashen = fk.CreateSkill{
  name = "ld__huashen",
}

Fk:loadTranslationTable{
  ["ld__huashen"] = "化身",
  [":ld__huashen"] = "当你需要发动“形”拥有的技能时，你可以于对应的时机发动“形”拥有的一个无技能标签的技能，然后于此技能结算后将拥有此技能的“形”置入武将牌堆。",

  ["#ld__huashen_remove"] = "化身：移去一张“形”",

  ["$ld__huashen1"] = "世间万物，贫道皆可化为其形。",
  ["$ld__huashen2"] = "尘身土塑，唯魂魄难得。",
}

---@param player ServerPlayer
---@param skillName string
local removeFangkeSkill = function(player, skillName)
  local room = player.room
  local skill = Fk.skills[skillName]
  room:removeTableMark(player, "ld__xing_skills", skillName)
  player:loseFakeSkill(skill)
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

huashen:addEffect(fk.AfterSkillEffect, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(huashen.name) and
      table.contains(player:getTableMark("ld__xing_skills"), data.skill:getSkeleton().name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, _, target, player, data)
    local all_xing = player:getMark("@&ld__xing")
    local choices = {}
    for _, s in ipairs(all_xing) do
      local general = Fk.generals[s]
      local skills = general:getSkillNameList()
      if table.contains(skills, data.skill:getSkeleton().name) then
        table.insert(choices, s)
      end
    end
    local choice = player.room:askToChoice(player, {
        choices = choices,
        skill_name = huashen.name,
        prompt = "#ld__huashen_remove",
      })
    removeFangke(player, choice)
  end,
})

return huashen
