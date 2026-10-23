local choufa = fk.CreateSkill{
  name = "choufa",
}

Fk:loadTranslationTable{
  ["choufa"] = "筹伐",
  [":choufa"] = "出牌阶段限一次，你可展示一名其他角色的一张手牌，其当前手牌中与此牌类别不同的牌均视为【杀】直到其回合结束。",

  ["#choufa"] = "筹伐：展示一名角色一张手牌，其手牌中不为此类别的牌均视为【杀】直到其回合结束",
  ["@@choufa-inhand"] = "筹伐",

  ["$choufa1"] = "秣马厉兵，筹伐不臣！",
  ["$choufa2"] = "枕戈待旦，秣马征平。",
}

choufa:addEffect("active", {
  anim_type = "control",
  prompt = "#choufa",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(choufa.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = choufa.name,
    })
    target:showCards(card)
    if not target.dead then
      for _, id in ipairs(target:getCardIds("h")) do
        if Fk:getCardById(id).type ~= Fk:getCardById(card).type then
          room:setCardMark(Fk:getCardById(id), "@@choufa-inhand", 1)
          Fk:filterCard(id, target)
        end
      end
    end
  end,
})
choufa:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@choufa-inhand", 0)
    end
    player:filterHandcards()
  end,
})
choufa:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@choufa-inhand") > 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

-- Choufa is a support conversion: choose a friendly non-empty hand with
-- enough public cards to make the temporary Slash pool meaningful.  The
-- category choice itself is deferred to the subsequent visible-card prompt.
choufa:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local best, best_value
    for _, target in ipairs(ai:getEnabledTargets()) do
      local relation = ai:getFactionRelation(target)
      local hand_num = type(target.getHandcardNum) == "function" and target:getHandcardNum() or 0
      local is_empty = type(target.isKongcheng) == "function" and target:isKongcheng()
      if relation and relation.state == "friend" and not is_empty and hand_num > 0 then
        local value = hand_num * 30
        if target.hp and target.hp < target.maxHp then value = value + 12 end
        if not best or value > best_value or (value == best_value and target.id < best.id) then
          best, best_value = target, value
        end
      end
    end
    if best then return { {}, { best } }, best_value end
  end,
})

-- The follow-up card is visible to the acting player.  Preserve the largest
-- possible number of cards as Slash by revealing a card from the smallest
-- category in that target hand.
choufa:addAI(Fk.Ltk.AI.newChooseCardStrategy {
  think = function(self, ai)
    local data = ai.data
    if type(data) ~= "table" then return end
    local target, flag = data[1], data[2]
    local ids, seen = {}, {}
    local function add(list)
      for _, id in ipairs(list or Util.DummyTable) do
        if type(id) == "number" and not seen[id] then
          seen[id] = true
          table.insert(ids, id)
        end
      end
    end
    if type(flag) == "table" then
      for _, group in ipairs(flag.card_data or Util.DummyTable) do add(group[2]) end
    elseif target and type(target.getCardIds) == "function" then
      add(target:getCardIds(flag or "h"))
    end
    if #ids == 0 then return end

    local counts = {}
    for _, id in ipairs(ids) do
      local card = Fk:getCardById(id)
      if card then
        local key = tostring(card.type)
        counts[key] = (counts[key] or 0) + 1
      end
    end
    local best, best_converted
    for _, id in ipairs(ids) do
      local card = Fk:getCardById(id)
      if card then
        local converted = #ids - (counts[tostring(card.type)] or #ids)
        if not best or converted > best_converted or
            (converted == best_converted and id < best) then
          best, best_converted = id, converted
        end
      end
    end
    if best then return best, best_converted * 30 end
  end,
})

return choufa
