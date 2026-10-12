

local command_skill = fk.CreateSkill{
  name = "#command_skill",
}

command_skill:addEffect("active", {
  can_use = Util.FalseFunc,
  target_num = 0,
  card_num = function(self, player)
    local x = 0
    if player:getHandcardNum() > 0 then x = x + 1 end
    if #player:getCardIds("e") > 0 then x = x + 1 end
    return x
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then
      return (Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip) ~=
      (Fk:currentRoom():getCardArea(selected[1]) == Card.PlayerEquip)
    end
    return #selected == 0
  end,
})

command_skill:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@@command4_effect-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id) return table.contains(player:getCardIds("h"), id) end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@command4_effect-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id) return table.contains(player:getCardIds("h"), id) end)
    end
  end,
})

command_skill:addEffect(fk.PreHpRecover, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@command5_effect-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data:preventRecover()
  end,
})

return command_skill
