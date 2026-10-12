
local yinhui = fk.CreateSkill {
  name = "yinhui",
}

Fk:loadTranslationTable{
  ["yinhui"] = "音洄",
  [":yinhui"] = "每轮开始时，你可以清除因此获得的技能，然后你选择一名其他角色当前拥有的一个技能获得之。",

  ["#yinhui-choose"] = "音洄：是否清除〖%arg〗并获得一名其他角色的一个技能",
  ["#yinhui-noclean"] = "音洄：是否获得一名其他角色的一个技能",
  ["#yinhui-choice"] = "音洄：获得 %dest 当前拥有的一个技能",

  ["$yinhui1"] = "日日闻弦聆音，自知此韵何意。",
  ["$yinhui2"] = "夜夜听水观澜，仿其声而弄此琴。",
}

local U = require "packages.utility.utility"

yinhui:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yinhui.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = player:getMark(yinhui.name) == 0 and "#yinhui-noclean" or "#yinhui-choose:::" .. player:getMark(yinhui.name),
      skill_name = yinhui.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(yinhui.name) ~= 0 then
      local skillName = player:getMark(yinhui.name)
      room:handleAddLoseSkills(player, "-" .. skillName)
      player:clearSkillHistory(skillName)
      room:setPlayerMark(player, yinhui.name, 0)
    end
    local to = event:getCostData(self).tos[1]
    local skills = to:getSkillNameList()
    if #skills > 0 then
      local choice = U.askToChooseSkills(player, {
        skill_name = yinhui.name,
        skills = skills,
        prompt = "#yinhui-choice::"..to.id,
        generals = { to.general },
      })[1]

      if not player:hasSkill(choice, true, true) then
        room:setPlayerMark(player, yinhui.name, choice)
        room:handleAddLoseSkills(player, choice)
      end
    end
  end,
})

return yinhui
