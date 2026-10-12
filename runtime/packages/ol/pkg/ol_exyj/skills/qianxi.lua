local qianxi = fk.CreateSkill {
  name = "ol_ex__qianxi",
}

Fk:loadTranslationTable{
  ["ol_ex__qianxi"] = "潜袭",
  [":ol_ex__qianxi"] = "出牌阶段开始时，你可以展示一张牌。若如此做，你距离为1的其他角色本回合不能使用或打出与“潜袭”牌颜色相同的手牌，"..
  "你本回合使用“潜袭”牌伤害基数值+1。",

  ["#ol_ex__qianxi-show"] = "潜袭：展示一张牌，本回合此牌伤害+1，距离1的角色不能使用打出此颜色手牌",
  ["@ol_ex__qianxi-turn"] = "潜袭",
  ["@@ol_ex__qianxi-inhand-turn"] = "潜袭",

  ["$ol_ex__qianxi1"] = "藏锋弑血头上刀，须臾剑影斩麒麟！",
  ["$ol_ex__qianxi2"] = "长史为其外，余暗为其内，魏延足定。",
}

qianxi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qianxi.name) and player.phase == Player.Play and
      not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qianxi.name,
      prompt = "#ol_ex__qianxi-show",
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards[1]
    local color = Fk:getCardById(card):getColorString()
    if table.contains(player:getCardIds("h"), card) then
      room:setCardMark(Fk:getCardById(card), "@@ol_ex__qianxi-inhand-turn", 1)
    end
    player:showCards(card)
    if player.dead or color == "nocolor" then return end
    for _, p in ipairs(room.alive_players) do
      if player:distanceTo(p) == 1 then
        room:doIndicate(player, {p})
        room:addTableMarkIfNeed(p, "@ol_ex__qianxi-turn", color)
      end
    end
  end,
})

qianxi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if table.contains(player:getTableMark("@ol_ex__qianxi-turn"), card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(player:getTableMark("@ol_ex__qianxi-turn"), card:getColorString()) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
})

qianxi:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    if target == player and data.card.is_damage_card then
      local ids = Card:getIdList(data.card)
      return #ids == 1 and Fk:getCardById(ids[1]):getMark("@@ol_ex__qianxi-inhand-turn") > 0
    end
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

return qianxi
