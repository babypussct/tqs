local jutu = fk.CreateSkill {
  name = "ty__jutu",
}

Fk:loadTranslationTable{
  ["ty__jutu"] = "据土",
  [":ty__jutu"] = "若你手牌数大于体力值，当你受到伤害时，你可以弃置一张红色牌防止该伤害。"..
    "每回合结束时，若你本回合未受到过伤害且手牌数小于等于体力值，你可以摸两张牌。",

  ["#ty__jutu-invoke"] = "据土：你可以弃置一张红色牌，防止此伤害",

  ["$ty__jutu1"] = "蜀川岁岁熟，何必起刀兵？",
  ["$ty__jutu2"] = "益州天府之国，不知何为饥馑。",
}

jutu:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jutu.name) and
      not player:isNude() and player:getHandcardNum() > player.hp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jutu.name,
      cancelable = true,
      pattern = ".|.|red",
      prompt = "#ty__jutu-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, jutu.name, player, player)
    data:preventDamage()
  end,
})

jutu:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jutu.name) and player:getHandcardNum() <= player.hp and
    #player.room.logic:getActualDamageEvents(1, function(e)
      return e.data.to == player
    end, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, jutu.name)
  end,
})

return jutu
