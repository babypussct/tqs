local chenshi = fk.CreateSkill {
  name = "os__chenshi",
}

Fk:loadTranslationTable{
  ["os__chenshi"] = "陈势",
  [":os__chenshi"] = "当其他角色使用<a href=':enemy_at_the_gates'>【兵临城下】</a>指定目标后，其可以交给你一张牌，将牌堆顶三张牌中"..
  "不为【杀】的牌置入弃牌堆；当其他角色成为<a href=':enemy_at_the_gates'>【兵临城下】</a>的目标后，其可以交给你一张牌，然后将牌堆顶三张牌中的"..
  "【杀】置入弃牌堆。",

  ["#os__chenshi-give1"] = "陈势：你可以交给 %src 一张牌，将牌堆顶三张牌中不为【杀】的牌置入弃牌堆",
  ["#os__chenshi-give2"] = "陈势：你可以交给 %src 一张牌，将牌堆顶三张牌中的【杀】置入弃牌堆",

  ["$os__chenshi1"] = "将军已为此二者所围，形势实不容乐观。",
  ["$os__chenshi2"] = "此二人若合力攻之，则将军危矣。",
}

chenshi:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenshi.name) and data.card.name == "enemy_at_the_gates" and player ~= target and
      not target:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      skill_name = chenshi.name,
      prompt = "#os__chenshi-give1:" .. player.id,
      cancelable = true,
    })
    if #card > 0 then
      room:doIndicate(target, {player})
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Player.Hand, player, fk.ReasonGive, chenshi.name, nil, false, target)
    local ids = table.filter(room:getNCards(3), function (id)
      return Fk:getCardById(id).trueName ~= "slash"
    end)
    if #ids > 0 then
      room:moveCards({
        ids = ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = chenshi.name,
      })
    end
    room:delay(1000)
  end,
})

chenshi:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenshi.name) and data.card.name == "enemy_at_the_gates" and player ~= target and
      not target:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      skill_name = chenshi.name,
      prompt = "#os__chenshi-give2:" .. player.id,
      cancelable = true,
    })
    if #card > 0 then
      room:doIndicate(target, {player})
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Player.Hand, player, fk.ReasonGive, chenshi.name, nil, false, target)
    local ids = table.filter(room:getNCards(3), function (id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    if #ids > 0 then
      room:moveCards({
        ids = ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = chenshi.name,
      })
    end
    room:delay(1000)
  end,
})

return chenshi
