local dimeng = fk.CreateSkill {
  name = "dimeng",
}

Fk:loadTranslationTable{
  ["dimeng"] = "缔盟",
  [":dimeng"] = "出牌阶段限一次，你可以选择两名其他角色并弃置X张牌（X为这些角色手牌数差），令这两名角色交换手牌。",

  ["#dimeng"] = "缔盟：选择两名其他角色，点击“确定”后，选择与其手牌数之差等量的牌，这两名角色交换手牌",
  ["#dimeng-discard"] = "缔盟：弃置 %arg 张牌，交换%src和%dest的手牌",

  ["$dimeng1"] = "以和为贵，以和为贵。",
  ["$dimeng2"] = "合纵连横，方能以弱胜强。",
}

dimeng:addEffect("active", {
  anim_type = "control",
  prompt = "#dimeng",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(dimeng.name, Player.HistoryPhase) == 0 and #Fk:currentRoom().alive_players > 2
  end,
  card_filter = function (self, player, to_select, selected, selected_targets)
    return #selected_targets == 2 and #selected < math.abs(selected_targets[1]:getHandcardNum() - selected_targets[2]:getHandcardNum())
    and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if to_select == player then
      return false
    end

    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return not (to_select:isKongcheng() and selected[1]:isKongcheng())
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if #selected == 2 then
      return #selected_cards == math.abs(selected[1]:getHandcardNum() - selected[2]:getHandcardNum())
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, dimeng.name, player, player)
    room:swapAllCards(player, effect.tos, dimeng.name)
  end,
})

-- Swap a high-hand enemy with a lower-hand ally.  The expected hand-count
-- swing is public; the exact card identities are intentionally not used.
-- Pay the mandatory difference with the least valuable legal cards.
dimeng:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local player = ai.player
    local best, best_value

    local function relation(target)
      return ai:getFactionRelation(target)
    end

    local function selectCheapest(cards, count)
      if #cards < count then return end
      table.sort(cards, function(a, b)
        local av = ai:getCardValue(a, "keep_value") or 0
        local bv = ai:getCardValue(b, "keep_value") or 0
        return av == bv and a < b or av < bv
      end)
      local selected = {}
      for i = 1, count do table.insert(selected, cards[i]) end
      return selected
    end

    local first_targets = ai:getEnabledTargets()
    ai:selectSkill(self.skill_name, true)
    for _, first in ipairs(first_targets) do
      ai:selectTarget(first, true)
      local second_targets = ai:getEnabledTargets()
      for _, second in ipairs(second_targets) do
        if second ~= player and second ~= first then
          ai:selectTarget(second, true)
          local first_hand = type(first.getHandcardNum) == "function" and first:getHandcardNum() or 0
          local second_hand = type(second.getHandcardNum) == "function" and second:getHandcardNum() or 0
          local difference = math.abs(first_hand - second_hand)
          local first_relation, second_relation = relation(first), relation(second)
          local friend, enemy
          if first_relation and first_relation.state == "friend" and
              second_relation and second_relation.state == "enemy" then
            friend, enemy = first, second
          elseif first_relation and first_relation.state == "enemy" and
              second_relation and second_relation.state == "friend" then
            friend, enemy = second, first
          end

          if friend and enemy and difference > 0 then
            local friend_hand = friend:getHandcardNum()
            local enemy_hand = enemy:getHandcardNum()
            local swing = enemy_hand - friend_hand
            if swing > 0 then
              local cards = selectCheapest(ai:getEnabledCards(), difference)
              if cards then
                local discard_cost = 0
                for _, id in ipairs(cards) do
                  discard_cost = discard_cost + (ai:getCardValue(id, "keep_value") or 0)
                end
                local value = swing * 30 - discard_cost
                if not best or value > best_value or
                    (value == best_value and (first.id .. ":" .. second.id) <
                      (best[2][1].id .. ":" .. best[2][2].id)) then
                  best, best_value = { cards, { first, second } }, value
                end
              end
            end
          end
          ai:unSelectAllCards()
          ai:selectTarget(second, false)
        end
      end
      ai:unSelectAll()
      ai:selectSkill(self.skill_name, true)
    end
    ai:unSelectAll()

    if best and best_value > 0 then return best, best_value end
  end,
})

return dimeng
