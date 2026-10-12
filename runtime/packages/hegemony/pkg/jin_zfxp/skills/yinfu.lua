
local yinfu = fk.CreateSkill {
  name = "heg__yinfu",
  tags = { Skill.MainPlace },
}

Fk:loadTranslationTable{
  ["heg__yinfu"] = "隐伏",
  [":heg__yinfu"] = "主将技，你计算体力时减少1点单独的阴阳鱼。每回合限一次，你可以暗置你的副将牌以视为使用一张【决斗】或【无懈可击】。",

  ["#heg__yinfu"] = "隐伏：暗置副将，视为使用一张【决斗】或【无懈可击】",
}

yinfu:addEffect("viewas", {
  mute = true,
  pattern = "duel,nullification",
  prompt = "#heg__yinfu",
  interaction = function(self, player)
    local all_names = { "duel", "nullification" }
    local names = player:getViewAsCardNames(yinfu.name, all_names)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = yinfu.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    player:broadcastSkillInvoke(yinfu.name)
    if self.interaction.data == "duel" then
      room:notifySkillInvoked(player, yinfu.name, "offensive")
    else
      room:notifySkillInvoked(player, yinfu.name, "control")
    end
    player:hideGeneral(true)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(yinfu.name, Player.HistoryTurn) == 0 and
      #player:getViewAsCardNames(yinfu.name, { "duel", "nullification" }) > 0 and
      player.deputyGeneral ~= "anjiang" and not player.deputyGeneral:startsWith("blank_")
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(yinfu.name, Player.HistoryTurn) == 0 and
      #player:getViewAsCardNames(yinfu.name, { "duel", "nullification" }) > 0 and
      player.deputyGeneral ~= "anjiang" and not player.deputyGeneral:startsWith("blank_")
  end,
  enabled_at_nullification = function (self, player, data)
    return player:usedSkillTimes(yinfu.name, Player.HistoryTurn) == 0 and
      player.deputyGeneral ~= "anjiang" and not player.deputyGeneral:startsWith("blank_")
  end,
})

return yinfu
