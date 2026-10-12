
local battleRoyal = fk.CreateSkill{
  name = "battle_royal&",
}
battleRoyal:addEffect("viewas", {
  pattern = "slash,jink",
  mute_card = false,
  mute = true,
  handly_pile = true,
  interaction = function(self, player)
    local names = {}
    if Fk.currentResponsePattern == nil and player:canUse(Fk:cloneCard("slash")) then
      table.insertIfNeed(names, "slash")
    else
      for _, name in ipairs{"slash", "jink"} do
        if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "peach"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
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
      use.card.trueName == "slash" and "offensive" or "defensive")
  end
})
battleRoyal:addEffect("prohibit", {
  name = "#battle_royal_prohibit&",
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
  ["battle_royal&"] = "鏖战",
  [":battle_royal&"] = "非转化的【桃】只能当【杀】或【闪】使用或打出。",
  ["#battle_royal_prohibit&"] = "鏖战",

  ["_heg__BattleRoyalMode_ignore"] = "无视鏖战",
}

return battleRoyal
