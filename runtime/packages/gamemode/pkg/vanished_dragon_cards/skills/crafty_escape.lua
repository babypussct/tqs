local skill = fk.CreateSkill {
  name = "crafty_escape_skill",
}

Fk:loadTranslationTable{
  ["#crafty_escape-ask"] = "是否使用【金蝉脱壳】，令%arg对你无效，你摸两张牌？",
}

skill:addEffect("cardskill", {
  can_use = Util.FalseFunc,
  on_effect = function(self, room, effect)
    local player = effect.from
    if effect.responseToEvent then
      effect.responseToEvent.nullified = true
    end
    player:drawCards(2, skill.name)
  end,
})

skill:addEffect(fk.TargetConfirming, {
  priority = 0.1,
  global = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and player:getHandcardNum() == 1 and data.card.type ~= Card.TypeEquip and data.from ~= player then
      player:filterHandcards()
      return Fk:getCardById(player:getCardIds("h")[1]).name == "crafty_escape" and
        not player:prohibitUse(Fk:getCardById(player:getCardIds("h")[1]))
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = skill.name,
      pattern = "crafty_escape",
      prompt = "#crafty_escape-ask:::" .. data.card:toLogString(),
      event_data = data,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local use = event:getCostData(self).extra_data
    use.toCard = data.card
    use.responseToEvent = data
    player.room:useCard(use)
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  priority = 0.1,
  global = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard and not player.dead then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "crafty_escape" then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, skill.name)
  end,
})

return skill
