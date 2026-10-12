
local qinling = fk.CreateSkill {
  name = "qinling",
}

Fk:loadTranslationTable{
  ["qinling"] = "侵凌",
  [":qinling"] = "每回合限一次，你可以弃置一张牌，视为使用一张【杀】。若此【杀】造成了伤害，你摸一张牌，否则将你弃置的牌置为“逆”。",

  ["#qinling"] = "侵凌：弃置一张牌，视为使用一张【杀】",

  ["$qinling1"] = "",
  ["$qinling2"] = "",
}

qinling:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  prompt = "#qinling",
  card_filter = function (self, player, to_select, selected, selected_targets)
    return #selected == 0 and not player:prohibitDiscard(to_select) and table.contains(player:getCardIds("h"), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = qinling.name
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    player.room:throwCard(use.card.fake_subcards, qinling.name, player, player)
  end,
  after_use = function (self, player, use)
    if not player.dead then
      if use and use.damageDealt then
        player:drawCards(1, qinling.name)
      else
        local id = use.card.fake_subcards[1]
        if player.room:getCardArea(id) == Card.DiscardPile then
          player:addToPile("liufeng_ni", id, true, qinling.name, player)
        end
      end
    end
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(qinling.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function (self, player, response)
    return not response and
      player:usedSkillTimes(qinling.name, Player.HistoryTurn) == 0 and not player:isNude()
  end,
})

return qinling