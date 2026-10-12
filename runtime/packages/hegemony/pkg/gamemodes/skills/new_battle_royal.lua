
local battleRoyal = fk.CreateSkill{
  name = "new_battle_royal&",
}
battleRoyal:addEffect("viewas", {
  pattern = "analeptic",
  mute_card = false,
  mute = true,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "peach"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("analeptic")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    if player:getMark("_heg__BattleRoyalMode_ignore") ~= 0 then return false end
    return table.find(player:getHandlyIds(true), function (id)
      return Fk:getCardById(id).trueName == "peach"
    end)
  end,
  enabled_at_response = function(self, player)
    if player:getMark("_heg__BattleRoyalMode_ignore") ~= 0 then return false end
    return table.find(player:getHandlyIds(true), function (id)
      return Fk:getCardById(id).trueName == "peach"
    end)
  end,
  before_use = function (self, player, use)
    local room = player.room
    room:notifySkillInvoked(player, battleRoyal.name,
    (use.extra_data or {}).analepticRecover and "support" or "offensive")
  end
})
battleRoyal:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if not card or card.trueName ~= "peach" or #card.skillNames > 0 or player:getMark("_heg__BattleRoyalMode_ignore") ~= 0 then return false end
    local subcards = Card:getIdList(card)
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player:getHandlyIds(true), id)
    end)
  end
})

-- battleRoyal:addAI(nil, "vs_skill")

Fk:loadTranslationTable{
  ["new_battle_royal&"] = "鏖战",
  [":new_battle_royal&"] = "非转化的【桃】只能当【酒】使用或打出。",
}

return battleRoyal
