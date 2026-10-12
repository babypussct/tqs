local mingfa = fk.CreateSkill {
  name = "mobile__mingfa",
}

Fk:loadTranslationTable{
  ["mobile__mingfa"] = "明伐",
  [":mobile__mingfa"] = "结束阶段，你可以展示一张牌。你下个回合的首个出牌阶段开始时，若此牌仍在你手牌或装备区，你可以用此牌与一名其他角色拼点，"..
  "若你：赢，你获得其一张牌，并随机获得牌堆中一张点数为X的牌（X为你拼点的牌的点数-1）；没赢，本回合你不能对其他角色使用牌。"..
  "当你拼点的牌亮出后，你令此牌的点数+2。",

  ["#mobile__mingfa-choose"] = "明伐：你可以用上回合展示的牌拼点",
  ["#mobile__mingfa-show"] = "明伐：你可以展示一张牌，下回合的出牌阶段可用此牌拼点",
  ["@@mobile__mingfa_fail-turn"] = "明伐失败",
  ["@$mobile__mingfa"] = "明伐",

  ["$mobile__mingfa1"] = "明日即为交兵之时，望尔等早做准备。",
  ["$mobile__mingfa2"] = "吾行明伐之策，不为掩袭之计。",
}

mingfa:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(mingfa.name) then
      if player.phase == Player.Finish then
        return not player:isNude()
      elseif player.phase == Player.Play then
        return #player:getTableMark("mobile__mingfa-turn") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Finish then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = mingfa.name,
        prompt = "#mobile__mingfa-show",
        cancelable = true,
      })
      if #card > 0 then
        event:setCostData(self, {cards = card})
        return true
      end
    elseif player.phase == Player.Play then
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Finish then
      local card = event:getCostData(self).cards
      room:addTableMarkIfNeed(player, "@$mobile__mingfa", card[1])
      player:showCards(card)
    elseif player.phase == Player.Play then
      local ids = table.filter(player:getTableMark("mobile__mingfa-turn"), function(id)
        return table.contains(player:getCardIds("he"), id)
      end)
      room:setPlayerMark(player, "mobile__mingfa-turn", 0)
      if #ids == 0 then return end
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
      if #targets == 0 then return end
      local tos, cards = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        min_num = 1,
        max_num = 1,
        targets = targets,
        pattern = tostring(Exppattern{ id = ids }),
        skill_name = mingfa.name,
        prompt = "#mobile__mingfa-choose",
        cancelable = true,
      })
      if #tos > 0 and #cards == 1 then
        local to = tos[1]
        local pindian = player:pindian({to}, mingfa.name, Fk:getCardById(cards[1]))
        if player.dead then return end
        if pindian.results[to].winner == player then
          if not to.dead and not to:isNude() then
            local id = room:askToChooseCard(player, {
              target = to,
              flag = "he",
              skill_name = mingfa.name,
            })
            room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, mingfa.name, nil, false, player)
          end
          if not player.dead then
            local x = Fk:getCardById(pindian.fromCard:getEffectiveId()).number - 1
            local get = room:getCardsFromPileByRule(".|"..x)
            if #get > 0 then
              room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, mingfa.name)
            end
          end
        else
          room:setPlayerMark(player, "@@mobile__mingfa_fail-turn", 1)
        end
      end
    end
  end,
})
mingfa:addEffect(fk.PindianCardsDisplayed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mingfa.name) and (player == data.from or data.results[player])
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:changePindianNumber(data, player, 2, mingfa.name)
  end,
})
mingfa:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@$mobile__mingfa") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "mobile__mingfa-turn", player:getMark("@$mobile__mingfa"))
    player.room:setPlayerMark(player, "@$mobile__mingfa", 0)
  end,
})
mingfa:addEffect("prohibit", {
  is_prohibited = function(self, from, to)
    return from and from:getMark("@@mobile__mingfa_fail-turn") > 0 and from ~= to
  end,
})

return mingfa
