local qiwu = fk.CreateSkill{
  name = "qiwu",
}

Fk:loadTranslationTable{
  ["qiwu"] = "栖梧",
  [":qiwu"] = "每回合你首次受到伤害时，若伤害来源为你或在你攻击范围内，你可弃置一张红色牌，防止此伤害。",

  ["#qiwu-invoke"] = "栖梧：你可以弃置一张红色牌，防止此伤害",

  ["$qiwu1"] = "诶~没打着~",
  ["$qiwu2"] = "除了飞来的暗箭，无物可伤我。",
}

qiwu:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  times = function (_, player)
    return 1 - player:usedSkillTimes(qiwu.name, Player.HistoryTurn)
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiwu.name) and
      player:usedSkillTimes(qiwu.name, Player.HistoryTurn) == 0 and not player:isNude() and
      data.from and (data.from == player or player:inMyAttackRange(data.from)) and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qiwu.name,
      cancelable = true,
      pattern = ".|.|heart,diamond",
      prompt = "#qiwu-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, qiwu.name, player, player)
    data:preventDamage()
  end,
})

return qiwu
