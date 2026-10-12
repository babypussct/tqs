
local guqu = fk.CreateSkill {
  name = "guqu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guqu"] = "顾曲",
  [":guqu"] = "锁定技，你的回合内：被展示过的手牌称为“阙”；手牌中有“阙”的其他角色只能使用“阙”；当有“阙”被使用后，你摸两张牌。",

  ["@@guqu-inhand-turn"] = "阙",

  ["$guqu1"] = "",
  ["$guqu2"] = "",
}

guqu:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guqu.name) and
      table.find(data:getMark("@@guqu-inhand-turn"), function (mark)
        return mark > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, guqu.name)
  end,
})

guqu:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(guqu.name, true) and player.room:getCurrent() == player
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(data.cardIds) do
      if target and table.contains(target:getCardIds("h"), id) then
        player.room:setCardMark(Fk:getCardById(id), "@@guqu-inhand-turn", 1)
      end
    end
  end,
})

guqu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local current = Fk:currentRoom():getCurrent()
    if current and current ~= player and current:hasSkill(guqu.name) and
      table.contains(player:getCardIds("h"), card.id) and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@guqu-inhand-turn") > 0
      end)
    then
      local subcards = card:isVirtual() and card.subcards or { card.id }
      return #subcards > 0 and
        table.find(subcards, function(id)
          return Fk:getCardById(id):getMark("@@guqu-inhand-turn") == 0
        end)
    end
  end,
})

return guqu
