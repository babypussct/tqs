
local fujingh = fk.CreateSkill {
  name = "fujingh",
}

Fk:loadTranslationTable {
  ["fujingh"] = "抚靖",
  [":fujingh"] = "出牌阶段限一次，你可以重铸任意张伤害牌，并额外摸X张牌（X为重铸的牌名数）。"..
  "若你因此重铸手牌中所有的伤害牌，你可以令一名其他角色获得其中一张牌。",

  ["#fujingh"] = "抚靖：重铸任意张伤害牌，额外摸牌名数张牌",
  ["#fujingh-choose"] = "抚靖：你可以令一名其他角色获得一张重铸的牌",
  ["#fujingh-prey"] = "抚靖：获得其中一张牌",
}

fujingh:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#fujingh",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(fujingh.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return Fk:getCardById(to_select).is_damage_card
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = #effect.cards
    local names = {}
    for _, id in ipairs(effect.cards) do
      table.insertIfNeed(names, Fk:getCardById(id).trueName)
    end
    local yes = not table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).is_damage_card and not table.contains(effect.cards, id)
    end)
    room:moveCardTo(effect.cards, Card.DiscardPile, nil, fk.ReasonRecast, fujingh.name, nil, true, player)
    room:sendFootnote(effect.cards, {
      type = "##RecastCard",
      from = player.id,
    })
    room:broadcastPlaySound("./audio/system/recast")
    room:sendLog{
      type = "#RecastBySkill",
      from = player.id,
      card = effect.cards,
      arg = fujingh.name,
    }
    if player.dead then return end
    player:drawCards(n + #names, fujingh.name)
    if player.dead then return end
    local cards = table.filter(effect.cards, function (id)
      return table.contains(room.discard_pile, id)
    end)
    if yes and #cards > 0 and #room:getOtherPlayers(player, false) > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#fujingh-choose",
        skill_name = fujingh.name,
      })
      if #to > 0 then
        to = to[1]
        local id = room:askToChooseCard(to, {
          target = to,
          flag = { card_data = { { fujingh.name, cards } } },
          skill_name = fujingh.name,
          prompt = "#fujingh-prey",
        })
        room:moveCardTo(id, Card.PlayerHand, to, fk.ReasonJustMove, fujingh.name, nil, true, to)
      end
    end
  end,
})

return fujingh
