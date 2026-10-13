local cangji = fk.CreateSkill {
  name = "v11__cangji",
}

Fk:loadTranslationTable{
  ["v11__cangji"] = "藏机",
  [":v11__cangji"] = "当你死亡时，你可以将你装备区里的所有牌移出游戏，然后你的下一名武将登场时将这些牌置入你的装备区。",
}

local U = require "packages.gamemode.pkg.1v1_generals.1v1_util"

cangji:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cangji.name, false, true) and #player:getCardIds("e") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("e")
    player.tag[cangji.name] = cards
    room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, cangji.name, nil, true, player)
  end,
})

cangji:addEffect(U.Debut, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.tag[cangji.name] ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(player.tag[cangji.name])
    player.tag[cangji.name] = nil
    room:moveCardIntoEquip(player, cards, cangji.name, false, player)
  end,
})

return cangji
