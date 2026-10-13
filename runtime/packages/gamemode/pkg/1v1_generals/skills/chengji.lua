local chengji = fk.CreateSkill {
  name = "v11__chengji",
}

Fk:loadTranslationTable{
  ["v11__chengji"] = "城棘",
  [":v11__chengji"] = "当你造成或受到伤害后，若“城棘”牌少于四张，你可以将造成伤害的牌置于你的武将牌上。"..
  "你死亡后，你的下一名武将登场时获得所有“城棘”牌。",
}

local U = require "packages.gamemode.pkg.1v1_generals.1v1_util"

local spec = {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengji.name) and data.card and #player:getPile(chengji.name) < 4 and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(chengji.name, data.card, true, chengji.name)
  end,
}
chengji:addEffect(fk.Damage, spec)
chengji:addEffect(fk.Damaged, spec)

chengji:addEffect(fk.Death, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile(chengji.name) > 0 and player.room:getSettings('gameMode') == "m_1v1_mode"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player.tag[chengji.name] = player:getPile(chengji.name)
    room:moveCardTo(player:getPile(chengji.name), Card.Void, nil, fk.ReasonJustMove, chengji.name, nil, true, player)
  end,
})

chengji:addEffect(U.Debut, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.tag[chengji.name]
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(player.tag[chengji.name])
    player.tag[chengji.name] = nil
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, chengji.name, nil, true, player)
  end,
})

return chengji
