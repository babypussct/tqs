local guyi = fk.CreateSkill {
  name = "guyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guyi"] = "孤熠",
  [":guyi"] = "锁定技，每回合限三次，当“熠”牌离开手牌区后，你观看牌堆顶X张牌，选择其中一张牌获得并标记为“熠”，"..
  "然后将其余牌以任意顺序置于牌堆顶（X为你本轮触发此效果的次数，至多为7）。"..
  "每回合开始时，若你手牌中没有“熠”，你摸一张牌并选择一张手牌标记为“熠”。",

  ["@@guyi-inhand"] = "熠",
  ["#guyi-ask"] = "孤熠：选择一张手牌标记为“熠”",
  ["#guyi-arrange"] = "孤熠：选择其中一张获得作为“熠”，将其余牌以任意顺序置于牌堆顶",

  ["$guyi1"] = "孤影照寒旌，忽见旧甲悬东壁，欲唤始觉非故人。",
  ["$guyi2"] = "雨中持炬唤天晴，莫谓星火微，终照山河醒。",
}

guyi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(guyi.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) < 3 then
      return table.find(data, function(move)
        if move.from == player then
          return table.find(move.moveInfo, function(info)
            return info.fromArea == Card.PlayerHand and info.beforeCard:getMark("@@guyi-inhand") > 0
          end) ~= nil
        end
      end)
    end
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = guyi.name
    local room = player.room
    local numTriggered = 0

    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and info.beforeCard:getMark("@@guyi-inhand") > 0 then
            numTriggered = numTriggered + 1
            if numTriggered > 1 then
              player:addSkillUseHistory(self.name)
            end

            local x = math.min(player:usedEffectTimes(self.name, Player.HistoryRound), 7)
            local toView = room:getNCards(x)
            room:turnOverCardsFromDrawPile(player, toView, skillName, false)
            local ret = room:askToArrangeCards(
              player,
              {
                card_map = { toView, "Top", "toObtain" },
                free_arrange = true,
                max_limit = { x, 1 },
                min_limit = { 0, 1 },
                skill_name = skillName,
                prompt = "#guyi-arrange",
              }
            )

            local top, toObtain = ret[1], ret[2]
            room:returnCardsToDrawPile(player, top, skillName, "top", false)
            if not player:isAlive() then
              return false
            end

            if room:getCardArea(toObtain[1]) == Card.Processing then
              room:obtainCard(player, toObtain, false, fk.ReasonPrey, player, skillName, "@@guyi-inhand")
            end
          end

          if not player:isAlive() then
            return false
          end
        end
      end
    end
  end,
})

guyi:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(guyi.name) and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@guyi-inhand") > 0
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(1, guyi.name)
    if not player:isKongcheng() then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        skill_name = guyi.name,
        include_equip = false,
        prompt = "#guyi-ask",
        cancelable = false,
      })
      room:setCardMark(Fk:getCardById(cards[1], true), "@@guyi-inhand", 1)
    end
  end,
})

return guyi
