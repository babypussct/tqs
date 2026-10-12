local yanru = fk.CreateSkill{
  name = "yanru",
  max_branches_use_time = {
    ["odd"] = {
      [Player.HistoryPhase] = 1
    },
    ["even"] = {
      [Player.HistoryPhase] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["yanru"] = "晏如",
  [":yanru"] = "出牌阶段各限一次，若你的手牌数为：奇数，你可以摸三张牌，然后弃置至少半数手牌；偶数，你可以弃置至少半数手牌，然后摸三张牌。",

  ["#yanru1"] = "晏如：你可以摸三张牌，然后弃置至少半数手牌",
  ["#yanru2"] = "晏如：你可以弃置至少%arg张手牌，然后摸三张牌",
  ["#yanru-discard"] = "晏如：请弃置至少%arg张手牌",

  ["$yanru1"] = "国有宁日，民有丰年，大同也。",
  ["$yanru2"] = "及臻厥成，天下晏如也。",
}

yanru:addEffect("active", {
  anim_type = "drawcard",
  min_card_num = 0,
  target_num = 0,
  prompt = function (self, player)
    if player:getHandcardNum() % 2 == 0 then
      return "#yanru2:::"..(player:getHandcardNum() // 2)
    else
      return "#yanru1"
    end
  end,
  can_use = function(self, player)
    if player:getHandcardNum() % 2 == 0 then
      return not player:isKongcheng() and yanru:withinBranchTimesLimit(player, "even", Player.HistoryPhase)
    else
      return yanru:withinBranchTimesLimit(player, "odd", Player.HistoryPhase)
    end
  end,
  card_filter = function (self, player, to_select, selected)
    if player:getHandcardNum() % 2 == 0 then
      return table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  target_filter = Util.FalseFunc,
  feasible = function (self, player, selected, selected_cards)
    if player:getHandcardNum() % 2 == 0 then
      return #selected_cards >= (player:getHandcardNum() // 2)
    else
      return true
    end
  end,
  history_branch = function(self, player, data)
    if player:getHandcardNum() % 2 == 0 then
      return "even"
    else
      return "odd"
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local data = effect.cost_data or {}
    if data.history_branch == "even" then
      room:setPlayerMark(player, "yanru2-phase", 1)
      room:throwCard(effect.cards, yanru.name, player, player)
      if not player.dead then
        player:drawCards(3, yanru.name)
      end
    else
      room:setPlayerMark(player, "yanru1-phase", 1)
      player:drawCards(3, yanru.name)
      if not player.dead and not player:isKongcheng() then
        local handcard_num = player:getHandcardNum()
        room:askToDiscard(player, {
          min_num = handcard_num // 2,
          max_num = handcard_num,
          include_equip = false,
          skill_name = yanru.name,
          prompt = "#yanru-discard:::"..(handcard_num // 2),
          cancelable = false,
        })
      end
    end
  end,
}, { check_skill_limit = true })

return yanru
