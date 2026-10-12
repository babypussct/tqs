local jingzhou = fk.CreateSkill {
  name = "peixiu_jingzhou",
}

Fk:loadTranslationTable {
  ["peixiu_jingzhou"] = "荆州",
  [":peixiu_jingzhou"] = "你获得此技能后，可以交给一名角色任意张手牌。",

  ["#peixiu_jingzhou-choose"] = "荆州：选择一名角色，交给其任意张手牌",
}

jingzhou:addEffect(fk.EventAcquireSkill, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jingzhou.name) and data.skill.name == jingzhou.name and
      not player:isKongcheng() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to, card = room:askToChooseCardsAndPlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = player:getHandcardNum(),
      pattern = ".|.|.|hand",
      prompt = "#peixiu_jingzhou-choose",
      skill_name = jingzhou.name,
      cancelable = true,
    })
    if #to > 0 and #card > 0 then
      event:setCostData(self, { tos = to, cards = card })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards or {}
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, jingzhou.name, nil, false, player)
  end
})

return jingzhou
