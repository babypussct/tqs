local qingyan = fk.CreateSkill{
  name = "m_shi__qingyan",
}

Fk:loadTranslationTable{
  ["m_shi__qingyan"] = "清严",
  [":m_shi__qingyan"] = "你可以展示X张手牌（X为本轮本技能发动次数，且至多为5），视为使用一张【闪】或【无懈可击】，然后此技能失效，"..
  "直至你手牌中没有以此法展示的牌。",

  ["#m_shi__qingyan"] = "清严：展示%arg张手牌，视为使用【闪】或【无懈可击】",
  ["@@m_shi__qingyan-inhand"] = "清严",

  ["$m_shi__qingyan1"] = "行如圭臬，无偏毫厘。",
  ["$m_shi__qingyan2"] = "既执权柄，不纵私欲。",
  ["$m_shi__qingyan3"] = "清风两袖，正色一堂。",
}

qingyan:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "jink,nullification",
  prompt = function (self, player)
    return "#m_shi__qingyan:::"..math.min(player:usedSkillTimes(qingyan.name, Player.HistoryRound) + 1, 5)
  end,
  interaction = function(self, player)
    local all_names = {"jink", "nullification"}
    local names = player:getViewAsCardNames(qingyan.name, all_names)
    if #names > 0 then
      return UI.CardNameBox {choices = names, all_choices = all_names}
    end
  end,
  filter_pattern = {
      min_num = 0,
      max_num = 0,
      pattern = "",
      subcards = {}
    },
  card_filter = function (self, player, to_select, selected, selected_targets)
    return table.contains(player:getCardIds("h"), to_select) and
      #selected < math.min(player:usedSkillTimes(qingyan.name, Player.HistoryRound) + 1, 5)
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or
      #cards ~= math.min(player:usedSkillTimes(qingyan.name, Player.HistoryRound) + 1, 5) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = qingyan.name
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    player:showCards(use.card.fake_subcards)
    for _, id in ipairs(use.card.fake_subcards) do
      if table.contains(player:getCardIds("h"), id) then
        room:setCardMark(Fk:getCardById(id), "@@m_shi__qingyan-inhand", 1)
      end
    end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return not response and
      player:getHandcardNum() > math.min(player:usedSkillTimes(qingyan.name, Player.HistoryRound), 5)
  end,
  enabled_at_nullification = function (self, player, data)
    return player:getHandcardNum() > math.min(player:usedSkillTimes(qingyan.name, Player.HistoryRound), 5)
  end,
})

qingyan:addEffect("invalidity", {
  invalidity_func = function (self, from, skill)
    if skill.name == qingyan.name then
      return table.find(from:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@m_shi__qingyan-inhand") > 0
    end)
    end
  end,
})

return qingyan
