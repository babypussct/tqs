local skill = fk.CreateSkill {
  name = "#real__crossbow_skill",
  tags = { Skill.Compulsory },
  attached_equip = "real__crossbow",
}

Fk:loadTranslationTable{
  ["#real__crossbow_skill"] = "真·诸葛连弩",
}

skill:addEffect("targetmod", {
  bypass_times = function(self, player, sk, scope, card)
    if player:hasSkill(skill.name) and card and card.trueName == "slash" and scope == Player.HistoryPhase then
      local cardIds = table.connect(Card:getIdList(card), card.fake_subcards)
      local crossbows = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == skill.attached_equip
      end)
      return #crossbows == 0 or not table.every(crossbows, function(id)
        return table.contains(cardIds, id)
      end)
    end
  end,
})

skill:addEffect(fk.PreCardUse, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(skill.name) and
      data.card.trueName == "slash" and
      data.card.number < 7 and
      data.card.number > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = player.room:getAllPlayers()
  end,
})

skill:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(skill.name) and
      player.phase == Player.Play and
      data.card.trueName == "slash" and
      not data.extraUse and
      player:usedCardTimes("slash", Player.HistoryPhase) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/crossbow")
    room:setEmotion(player, "./packages/standard_cards/image/anim/crossbow")
    room:sendLog{
      type = "#InvokeSkill",
      from = player.id,
      arg = "real__crossbow",
    }
  end,
})

return skill
