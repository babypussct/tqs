local sk = fk.CreateSkill {
  name = "#v11_lb__crossbow_skill",
  tags = { Skill.Compulsory },
  attached_equip = "v11_lb__crossbow",
}

sk:addEffect("targetmod", {
  residue_func = function (self, player, skill, scope, card, to)
    if player:hasSkill(sk.name) and card and card.trueName == "slash" and scope == Player.HistoryPhase then
      local cardIds = table.connect(Card:getIdList(card), card.fake_subcards)
      local crossbows = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == sk.attached_equip
      end)
      if #crossbows == 0 or not table.every(crossbows, function(id)
        return table.contains(cardIds, id)
      end) then
        return 3
      end
    end
  end,
})

sk:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(sk.name) and player.phase == Player.Play and
      data.card.trueName == "slash" and not data.extraUse and player:usedCardTimes("slash", Player.HistoryPhase) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/crossbow")
    room:setEmotion(player, "./packages/standard_cards/image/anim/crossbow")
    room:sendLog{
      type = "#InvokeSkill",
      from = player.id,
      arg = "v11_lb__crossbow",
    }
  end,
})

return sk
