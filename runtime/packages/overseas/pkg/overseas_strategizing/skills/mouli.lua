local mouli = fk.CreateSkill {
  name = "os__mouli",
}

Fk:loadTranslationTable{
  ["os__mouli"] = "谋立",
  [":os__mouli"] = "每回合限一次，当你需要使用基本牌时，你可以使用牌堆中随机一张的你需要的基本牌。",

  ["#os__mouli"] = "谋立：从牌堆使用一张你需要的基本牌",
  ["os__mouliFailed"] = "谋立失败，牌堆中没有该基本牌",

  ["$os__mouli1"] = "僣孽为害，吾岂可谋而不行？",
  ["$os__mouli2"] = "澄汰王室，迎立宗子。",
}

mouli:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#os__mouli",
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(mouli.name, all_names, {})
    return UI.CardNameBox { choices = names, all_choices = all_names}
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  filter_pattern = {
      min_num = 0,
      max_num = 0,
      pattern = "",
      subcards = {},
  },
  view_as = function(self)
    if self.interaction.data == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, mouli.name)
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cids = table.filter(room.draw_pile, function (id)
      local card = Fk:getCardById(id)
      return card.name == self.interaction.data and not player:prohibitUse(card)
    end)
    if #cids > 0 then
      use.card:addSubcard(room:tableRandomPick(cids))
    else
      room:doBroadcastNotify("ShowToast", Fk:translate("os__mouliFailed"))
      return mouli.name
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(mouli.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(mouli.name, Player.HistoryTurn) == 0
  end,
})

return mouli
