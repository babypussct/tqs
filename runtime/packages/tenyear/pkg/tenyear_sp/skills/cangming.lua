local cangming = fk.CreateSkill {
  name = "cangming",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cangming"] = "沧溟",
  [":cangming"] = "锁定技，游戏开始时，所有角色同时将手牌置于武将牌上，称为“溟”；当有牌被置为“溟”后，每有一种颜色，你摸一张牌；" ..
  "一名角色受到伤害后或其回合开始时，该角色获得其所有“溟”。",

  ["$cangming_ming"] = "溟",

  ["$cangming1"] = "沧溟起幕，万类归流，百川当濯我足！",
  ["$cangming2"] = "乾坤浩荡，我主沉浮！",
}

cangming:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cangming.name)
  end,
  on_use = function(self, event, target, player, data)
    local moveList = {}
    table.forEach(player.room:getAlivePlayers(), function(p)
      if not p:isKongcheng() then
        table.insert(moveList, {
          ids = p:getCardIds("h"),
          from = p,
          to = p,
          toArea = Card.PlayerSpecial,
          moveReason = fk.ReasonJustMove,
          specialName = "$cangming_ming",
          moveVisible = false,
        })
      end
    end)

    player.room:moveCards(table.unpack(moveList))
  end,
})

cangming:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(cangming.name) and
      table.find(data, function(move)
        return move.toArea == Card.PlayerSpecial and move.specialName == "$cangming_ming"
      end)
  end,
  on_use = function(self, event, target, player, data)
    local colors = {}
    table.forEach(data, function(move)
      if move.toArea == Card.PlayerSpecial and move.specialName == "$cangming_ming" then
        table.forEach(move.moveInfo, function(info)
          table.insertIfNeed(colors, Fk:getCardById(info.cardId).color)
        end)
      end
    end)

    player:drawCards(#colors, cangming.name)
  end,
})

local spec = {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("$cangming_ming") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, player:getPile("$cangming_ming"), false, fk.ReasonPrey, player, cangming.name)
  end,
}

cangming:addEffect(fk.Damaged, spec)
cangming:addEffect(fk.TurnStart, spec)

return cangming
