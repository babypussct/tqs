local jianming = fk.CreateSkill {
  name = "os__jianming",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__jianming"] = "剑鸣",
  [":os__jianming"] = "锁定技，每回合每种花色限一次，当你使用或打出【杀】时，或当你因拼点失去牌时，你摸一张牌。",

  ["@os__jianming-turn"] = "剑鸣",

  ["$os__jianming1"] = "弹剑作谱，鸣之铮铮。",
  ["$os__jianming2"] = "剑鸣凄凄，穿心刺骨。",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianming.name) and
      data.card.trueName == "slash" and data.card.suit ~= Card.NoSuit and
      not table.contains(player:getTableMark("@os__jianming-turn"), data.card:getSuitString(true))
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "@os__jianming-turn", data.card:getSuitString(true))
    player:drawCards(1, jianming.name)
  end,
}
jianming:addEffect(fk.CardUsing, spec)
jianming:addEffect(fk.CardResponding, spec)

jianming:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(jianming.name) and
      player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian) and
      #player:getTableMark("@os__jianming-turn") < 4 then
      local suits = {}
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonPindian then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              not table.contains(player:getTableMark("@os__jianming-turn"), Fk:getCardById(info.cardId):getSuitString(true)) then
              table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString(true))
            end
          end
        end
      end
      if #suits > 0 then
        event:setCostData(self, {choice = suits})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local suits = event:getCostData(self).choice
    local mark = player:getTableMark("@os__jianming-turn")
    table.insertTableIfNeed(mark, suits)
    room:setPlayerMark(player, "@os__jianming-turn", mark)
    player:drawCards(#suits, jianming.name)
  end,
})

return jianming
