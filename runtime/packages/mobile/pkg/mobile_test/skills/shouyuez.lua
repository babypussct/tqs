local shouyue = fk.CreateSkill {
  name = "shouyuez",
  related_skills = { "qinyin" },
}

Fk:loadTranslationTable{
  ["shouyuez"] = "授乐",
  [":shouyuez"] = "摸牌阶段开始时，或当你的体力减少后，你可以选择一项：1.摸一张牌，令一名角色获得技能〖琴音〗" ..
  "（已有则改为其摸一张牌）；2.令一名角色复原武将牌。",

  ["#shouyuez-invoke"] = "授乐：你可选择一项发动",
  ["@@shouyuez_qinyin"] = "授乐 获得琴音",

  ["$shouyuez1"] = "声无哀乐，乐无雅俗，但寄己心而已。",
  ["$shouyuez2"] = "听之忘忧，习之养性，诚为修身之宝。",
}

local shouyueOnCost = function(self, event, target, player, data)
  local success, dat = player.room:askToUseActiveSkill(
    player,
    {
      skill_name = "shouyuez_choose",
      prompt = "#shouyuez-invoke",
    }
  )

  if success and dat and dat.interaction and dat.targets then
    event:setCostData(self, { choice = dat.interaction, tos = dat.targets })
    return true
  end
end

local shouyueOnUse = function(self, event, target, player, data)
  ---@type string
  local skillName = shouyue.name
  local costData = event:getCostData(self)
  local choice = costData.choice
  local to = costData.tos[1]

  if choice == "shouyuez_restore" then
    to:reset()
  else
    player:drawCards(1, skillName)
    if to:isAlive() then
      if to:hasSkill("qinyin", true) then
        to:drawCards(1, skillName)
      else
        local room = player.room
        room:setPlayerMark(to, "@@shouyuez_qinyin", 1)
        room:handleAddLoseSkills(to, "qinyin")
      end
    end
  end
end

shouyue:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:hasSkill(shouyue.name)
  end,
  on_cost = shouyueOnCost,
  on_use = shouyueOnUse,
})

shouyue:addEffect(fk.HpChanged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.num < 0 and player:hasSkill(shouyue.name)
  end,
  on_cost = shouyueOnCost,
  on_use = shouyueOnUse,
})

shouyue:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.skill.name == "qinyin" and player:getMark("@@shouyuez_qinyin") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@shouyuez_qinyin", 0)
  end,
})

return shouyue
