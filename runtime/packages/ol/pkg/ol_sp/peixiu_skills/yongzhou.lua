local yongzhou = fk.CreateSkill {
  name = "peixiu_yongzhou",
}

Fk:loadTranslationTable {
  ["peixiu_yongzhou"] = "雍州",
  [":peixiu_yongzhou"] = "你获得此技能后，可以摸两张牌，然后将手牌弃至手牌上限。",

  ["#peixiu_yongzhou-invoke"] = "雍州：是否摸两张牌，然后将手牌弃至手牌上限？",
}

yongzhou:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yongzhou.name) and data.skill.name == yongzhou.name
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yongzhou.name,
      prompt = "#peixiu_yongzhou-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(2, yongzhou.name)
    local n = player:getHandcardNum() - player:getMaxCards()
    if n > 0 then
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = yongzhou.name,
        cancelable = false,
      })
    end
  end,
})

return yongzhou
