local osYanshih = fk.CreateSkill {
  name = "os__yanshih",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__yanshih"] = "延势",
  [":os__yanshih"] = "一级：限定技，你可将一张【杀】当【决斗】、【兵临城下】或<a href='bag_of_tricks'>智囊</a>牌使用。<br/>" ..
  "二级：限定技，你可将一张【杀】当【决斗】、【兵临城下】或<a href='bag_of_tricks'>智囊</a>牌使用。<a href='os__veteran'>历战</a>：复原此技能。",

  ["@@os__yanshiUp"] = "延势 已升级",

  ["$os__yanshih1"] = "今破曹军，明日当直取许都！",
  ["$os__yanshih2"] = "全军整肃，此战不得有失！",
}

osYanshih:addEffect("viewas", {
  pattern = "duel,enemy_at_the_gates,dismantlement,nullification,ex_nihilo",
  interaction = function(self, player)
    local all_names = { "duel", "enemy_at_the_gates", "dismantlement", "nullification", "ex_nihilo" }
    local names = player:getViewAsCardNames(osYanshih.name, all_names)
    if #names > 0 then
      return UI.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard(self.interaction.data)
    c.skillName = osYanshih.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(osYanshih.name, Player.HistoryGame) == 0
  end,
  enabled_at_response = function (self, player, response)
    return player:usedSkillTimes(osYanshih.name, Player.HistoryGame) == 0 and not response
  end,
})

osYanshih:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player)
    return player == target and player:usedSkillTimes(osYanshih.name) > 0 and player:getMark("@@os__yanshiUp") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    player:setSkillUseHistory(osYanshih.name, 0, Player.HistoryGame)
  end,
})

return osYanshih
