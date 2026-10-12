local shameng = fk.CreateSkill {
  name = "shameng",
}

Fk:loadTranslationTable{
  ["shameng"] = "歃盟",
  [":shameng"] = "出牌阶段限一次，你可以弃置两张颜色相同的手牌并选择一名其他角色，该角色摸两张牌，然后你摸三张牌。",

  ["#shameng"] = "歃盟：弃置两张颜色相同的手牌，令一名其他角色摸两张牌，你摸三张牌",

  ["$shameng1"] = "震以不才，得充下使，愿促两国盟好。",
  ["$shameng2"] = "震奉聘叙好，若有违贵国典制，万望告之。",
}

shameng:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#shameng",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shameng.name, Player.HistoryPhase) == 0 and player:getHandcardNum() > 1
  end,
  card_filter = function(self, player, to_select, selected)
    if table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select) then
      return #selected == 0 or Fk:getCardById(selected[1]):compareColorWith(Fk:getCardById(to_select))
    end
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, shameng.name, player, player)
    if not target.dead then
      target:drawCards(2, shameng.name)
    end
    if not player.dead then
      player:drawCards(3, shameng.name)
    end
  end,
})

return shameng
