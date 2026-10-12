local heng = fk.CreateSkill {
  name = "mobile__natu_heng",
}

Fk:loadTranslationTable {
  ["mobile__natu_heng"] = "恒",
  [":mobile__natu_heng"] = "每轮限一次，若你手牌中没有：<br>" ..
      "1.非伤害牌，你可以视为使用或打出一张【闪】；<br>" ..
      "2.伤害牌，你可以视为使用或打出一张不计次数且无次数限制的【杀】。",

  ["#heng-slash"] = "恒：视为使用或打出一张无次数限制的【杀】",
  ["#heng-jink"] = "恒：视为使用或打出一张【闪】",

  ["$mobile__natu_heng1"] = "一生为了汉室，一心为了主公。",
  ["$mobile__natu_heng2"] = "纵有千难万险，这颗心也不会变！",
}

heng:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = function(self, player, selected_cards, selected)
    return "#heng-" .. self.interaction.data
  end,
  interaction = function(self, player)
    local all_names = { "slash", "jink" }
    if table.find(player:getCardIds("h"), function(id)
          return not Fk:getCardById(id).is_damage_card
        end) then
      table.removeOne(all_names, "jink")
    end
    if table.find(player:getCardIds("h"), function(id)
          return Fk:getCardById(id).damage_type ~= nil
        end) then
      table.removeOne(all_names, "slash")
    end
    local names = player:getViewAsCardNames(heng.name, all_names)
    return UI.CardNameBox { choices = names, all_choices = all_names}
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = heng.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(heng.name, Player.HistoryRound) == 0 and
        #player:getViewAsCardNames(heng.name, { "slash" }) > 0 and
        not table.find(player:getCardIds("h"), function(id)
          return Fk:getCardById(id).damage_type ~= nil
        end)
  end,
  enabled_at_response = function(self, player, response)
    if player:usedSkillTimes(heng.name, Player.HistoryRound) == 0 then
      if not table.find(player:getCardIds("h"), function(id)
            return not Fk:getCardById(id).is_damage_card
          end) and
          #player:getViewAsCardNames(heng.name, { "jink" }) > 0 then
        return true
      end
      if not table.find(player:getCardIds("h"), function(id)
            return Fk:getCardById(id).damage_type ~= nil
          end) and
          #player:getViewAsCardNames(heng.name, { "slash" }) > 0 then
        return true
      end
    end
  end,
})

heng:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, heng.name)
  end,
})

return heng
