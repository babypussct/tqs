local zhuning = fk.CreateSkill {
  name = "zhuning",
}

Fk:loadTranslationTable{
  ["zhuning"] = "诛佞",
  [":zhuning"] = "出牌阶段限一次，你可以交给一名其他角色任意张牌，这些牌标记为“隙”，然后你可以视为使用一张不计次数的【杀】或伤害类锦囊牌，"..
  "然后若此牌没有造成伤害，此技能本阶段改为“出牌阶段限两次”。",

  ["#zhuning"] = "诛佞：交给一名角色任意张牌（标记为“隙”），然后视为使用一张伤害牌",
  ["@@zhuning-inhand"] = "隙",
  ["#zhuning-use"] = "诛佞：你可以视为使用一张不计次数的伤害牌",

  ["$zhuning1"] = "此剑半丈，当斩奸佞人头！",
  ["$zhuning2"] = "此身八尺，甘为柱国之石。",
}

zhuning:addEffect("active", {
  anim_type = "support",
  prompt = "#zhuning",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhuning.name, Player.HistoryPhase) < 1 + player:getMark("zhuning-phase")
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, zhuning.name, nil, false, player, "@@zhuning-inhand")
    if player.dead then return end
    local names = table.filter(Fk:getAllCardNames("bt"), function(name)
      local card = Fk.all_card_types[name]
      return card.trueName == "slash" or (card.type == Card.TypeTrick and card.is_damage_card)
    end)
    local use = room:askToUseVirtualCard(player, {
      name = names,
      skill_name = zhuning.name,
      prompt = "#zhuning-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
    })
    if use and not player.dead and not use.damageDealt then
      room:setPlayerMark(player, "zhuning-phase", 1)
    end
  end,
})

return zhuning
