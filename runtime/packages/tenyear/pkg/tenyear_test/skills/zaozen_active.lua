local zaozen_active = fk.CreateSkill {
  name = "zaozen&",
}

Fk:loadTranslationTable{
  ["zaozen&"] = "遭谮",
  [":zaozen&"] = "出牌阶段限一次，你可以弃置一张非基本牌，然后令王笙视为对一名角色使用一张【杀】，"..
  "若此【杀】造成伤害，本回合其视为所有【杀】的使用者；若此【杀】未造成伤害，其视为对你依次使用两张【杀】。",

  ["#zaozen&"] = "遭谮：弃置一张非基本牌，令王笙视为对一名角色使用【杀】",
}

zaozen_active:addEffect("active", {
  mute = true,
  prompt = "#zaozen&",
  card_num = 1,
  target_num = 2,
  can_use = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function (p)
      return p ~= player and p:hasSkill("zaozen") and p:usedSkillTimes("zaozen", Player.HistoryPhase) == 0
    end)
  end,
  card_filter = function (self, player, to_select, selected, selected_targets)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic and
      not player:prohibitDiscard(to_select)
  end,
  target_filter = function (self, player, to_select, selected)
    if #selected == 0 then
      return to_select:hasSkill("zaozen") and to_select:usedSkillTimes("zaozen", Player.HistoryPhase) == 0
    else
      return selected[1]:canUseTo(Fk:cloneCard("slash", nil, nil, "zaozen"), to_select, { bypass_distances = false, bypass_times = true })
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local to = effect.tos[2]
    room:notifySkillInvoked(target, "zaozen", "offensive")
    target:broadcastSkillInvoke("zaozen")
    target:addSkillUseHistory("zaozen", 1)
    room:throwCard(effect.cards, "zaozen", player, player)
    if to.dead then return end
    local use = room:useVirtualCard("slash", nil, target, to, "zaozen", true)
    if use then
      if use.damageDealt then
        if not target.dead then
          room:setPlayerMark(target, "@@zaozen-turn", 1)
        end
      else
        for _ = 1, 2 do
          if player.dead then return end
          room:useVirtualCard("slash", nil, target, player, "zaozen", true)
        end
      end
    end
  end,
})

return zaozen_active
