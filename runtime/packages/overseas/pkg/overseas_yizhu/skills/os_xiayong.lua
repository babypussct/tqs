local osXiayong = fk.CreateSkill {
  name = "os__xiayong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__xiayong"] = "狭勇",
  [":os__xiayong"] = "锁定技，你为目标角色或使用者的【决斗】造成伤害时，若受到此牌伤害的角色：为你，你随机弃置一张手牌；不为你，此伤害+1。",

  ["$os__xiayong1"] = "一招之差，不足决此战胜负！",
  ["$os__xiayong2"] = "这般身手，也敢来战我？",
}

osXiayong:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(osXiayong.name) and data.card and data.card.trueName == "duel") then
      return false
    end

    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, false)
    if use_event == nil then return false end
    return
      (table.contains(use_event.data.tos, player) or use_event.data.from == player) and
      player.room.logic:damageByCardEffect(false) and
      (data.to ~= player or not player:isKongcheng())
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osXiayong.name
    local room = player.room
    if data.to == player then
      room:notifySkillInvoked(player, skillName, "negative")
      player:broadcastSkillInvoke(skillName, 1)
      local cards = table.filter(player:getCardIds("h"), function(id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end)
      if #cards > 0 then
        room:throwCard(room:tableRandomPick(cards), skillName, player, player)
      end
    else
      room:notifySkillInvoked(player, skillName, "offensive")
      player:broadcastSkillInvoke(skillName, 2)
      room:doIndicate(player, { data.to })
      data:changeDamage(1)
    end
  end,
})

return osXiayong
