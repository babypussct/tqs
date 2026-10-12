local kuiji = fk.CreateSkill {
  name = "changshi__kuiji",
}

Fk:loadTranslationTable{
  ["changshi__kuiji"] = "窥机",
  [":changshi__kuiji"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并可弃置你与其手牌中共计四张花色各不相同的牌。",

  ["#changshi__kuiji"] = "窥机：观看一名角色的手牌，并可弃置你与其手牌中四张花色各不相同的牌",
  ["#changshi__kuiji-ask"] = "窥机：弃置双方手里四张不同花色的牌",

  ["$changshi__kuiji1"] = "同道者为忠，殊途者为奸！",
}

Fk:addPoxiMethod{
  name = "changshi__kuiji",
  prompt = "#changshi__kuiji-ask",
  card_filter = function(to_select, selected, data)
    local suit = Fk:getCardById(to_select).suit
    if suit == Card.NoSuit then return false end
    return not table.find(selected, function(id) return Fk:getCardById(id).suit == suit end)
    and not (Self:prohibitDiscard(Fk:getCardById(to_select)) and table.contains(data[1][2], to_select))
  end,
  feasible = function(selected)
    return #selected == 4
  end,
}
kuiji:addEffect("active", {
  anim_type = "control",
  prompt = "#changshi__kuiji",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kuiji.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local player_hands = player:getCardIds("h")
    local target_hands = target:getCardIds("h")
    local cards = room:askToPoxi(player, {
      poxi_type = "changshi__kuiji",
      data = {
        { player.general, player_hands },
        { target.general, target_hands },
      },
      cancelable = true,
    })
    if #cards == 0 then return end
    local cards1 = table.filter(cards, function(id) return table.contains(player_hands, id) end)
    local cards2 = table.filter(cards, function(id) return table.contains(target_hands, id) end)
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = kuiji.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = kuiji.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
  end,
})

return kuiji
