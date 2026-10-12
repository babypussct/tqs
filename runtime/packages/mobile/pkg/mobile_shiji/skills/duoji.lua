local duoji = fk.CreateSkill {
  name = "duoji",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["duoji"] = "夺冀",
  [":duoji"] = "限定技，出牌阶段，你可以弃置两张手牌，获得一名其他角色装备区内所有的牌。",

  ["#duoji"] = "夺冀：你可以弃置两张手牌，获得一名其他角色装备区内所有的牌！",

  ["$duoji1"] = "将军若献冀州，必安如泰山也。",
  ["$duoji2"] = "袁氏得冀州，必厚德将军。",
}

duoji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#duoji",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(duoji.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and #to_select:getCardIds("e") > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, duoji.name, player, player)
    if player.dead or target.dead or #target:getCardIds("e") == 0 then return end
    room:obtainCard(player, target:getCardIds("e"), true, fk.ReasonPrey, player, duoji.name)
  end,
})

return duoji
