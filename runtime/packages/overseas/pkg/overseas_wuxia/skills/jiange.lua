local jiange = fk.CreateSkill {
  name = "os__jiange",
}

Fk:loadTranslationTable{
  ["os__jiange"] = "剑歌",
  [":os__jiange"] = "每回合限一次，你可以将一张非基本牌当【杀】使用或打出（无距离与次数限制且不计入次数）。若此时为你的回合外，你摸一张牌。",

  ["#os__jiange"] = "剑歌：将一张非基本牌当【杀】使用或打出（无距离次数限制）",

  ["$os__jiange1"] = "纵剑为舞，击缶而歌！",
  ["$os__jiange2"] = "辞亲历山野，仗剑唱大风！",
}

jiange:addEffect("viewas", {
  prompt = "#os__jiange",
  pattern = "slash",
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c:addSubcards(cards)
    c.skillName = jiange.name
    return c
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    if player.room.current ~= player then
      player:drawCards(1, jiange.name)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(jiange.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player)
    return player:usedSkillTimes(jiange.name, Player.HistoryTurn) == 0
  end,
})

jiange:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and table.contains(card.skillNames, jiange.name)
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, jiange.name)
  end,
})

return jiange
