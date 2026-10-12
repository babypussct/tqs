local dingzhou = fk.CreateSkill {
  name = "dingzhou",
}

Fk:loadTranslationTable{
  ["dingzhou"] = "定州",
  [":dingzhou"] = "出牌阶段限一次，你可以选择一名其他角色并交给其X张牌（X为其场上的牌数），然后你获得其场上的所有牌。",

  ["#dingzhou"] = "定州：你交给一名其他角色其场上牌数的牌，获得其场上的牌",

  ["$dingzhou1"] = "今肃亲往，主公何愁不定！",
  ["$dingzhou2"] = "肃之所至，万事皆平！",
}

dingzhou:addEffect("active", {
  anim_type = "control",
  prompt = "#dingzhou",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(dingzhou.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = Util.TrueFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local n = #to_select:getCardIds("ej")
    return #selected == 0 and to_select ~= player and n > 0 and n == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:obtainCard(target, effect.cards, false, fk.ReasonGive, player, dingzhou.name)
    if #target:getCardIds("ej") > 0 and not player.dead then
      room:obtainCard(player, target:getCardIds("ej"), false, fk.ReasonPrey, player, dingzhou.name)
    end
  end,
})

return dingzhou
