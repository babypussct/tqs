local shangjian = fk.CreateSkill {
  name = "shangjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shangjian"] = "尚俭",
  [":shangjian"] = "锁定技，一名角色的结束阶段，若你于此回合失去的牌（非因使用装备牌而失去的牌数与你使用装备牌的过程中未进入你装备区的牌数之和）"..
  "不大于你的体力值，你摸等同于失去数量的牌。",

  ["@shangjian-turn"] = "尚俭",

  ["$shangjian1"] = "如今乱世，当秉俭行之节。",
  ["$shangjian2"] = "百姓尚处寒饥之困，吾等不可奢费财力。",
}

shangjian:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(shangjian.name) and
      target.phase == Player.Finish and
      player:getMark("shangjian-turn") > 0 and
      player:getMark("shangjian-turn") <= player.hp
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, player:getMark("shangjian-turn"), shangjian.name)
  end,
})

shangjian:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    local fuckYoka = {}
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData then
      local use = parentUseData.data
      if use.card.type == Card.TypeEquip and use.from == player then
        fuckYoka = Card:getIdList(use.card)
      end
    end
    local x = 0
    for _, move in ipairs(data) do
      if move.from == player then
        x = x + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and not table.contains(fuckYoka, info.cardId)
        end)
      end
      if move.to ~= player or move.toArea ~= Card.PlayerEquip then
        x = x + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.Processing) and table.contains(fuckYoka, info.cardId)
        end)
      end
    end
    if x > 0 then
      event:setCostData(self, { x = x })
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "shangjian-turn", event:getCostData(self).x)
    if player:hasSkill(shangjian.name, true) then
      player.room:setPlayerMark(player, "@shangjian-turn", player:getMark("shangjian-turn"))
    end
  end,
})

return shangjian
