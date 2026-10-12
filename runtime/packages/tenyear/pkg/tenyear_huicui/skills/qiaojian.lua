
local qiaojian = fk.CreateSkill{
  name = "qiaojian",
}

Fk:loadTranslationTable{
  ["qiaojian"] = "巧谏",
  [":qiaojian"] = "出牌阶段每名角色限一次，你可以选择一名其他角色，双方同时弃置任意张牌，若你弃置牌点数之和较大，你回复1点体力并选择一项令其执行："..
  "1.其下个回合首次使用【杀】与锦囊牌可各额外结算一次；2.其下个回合不可使用伤害牌。否则，你获得双方弃置牌并不计入手牌上限。",

  ["#qiaojian"] = "巧谏：与一名角色同时弃置任意张牌，根据点数大小执行效果",
  ["#qiaojian-discard"] = "巧谏：弃置任意张牌，根据点数大小执行效果",
  ["#qiaojian-choice"] = "巧谏：选择令 %dest 执行的选项",
  ["qiaojian_extra"] = "下回合使用【杀】与锦囊牌可额外结算",
  ["qiaojian_prohibit"] = "下回合不可使用伤害牌",
  ["#qiaojian-invoke"] = "巧谏：是否令%arg额外结算一次？",
  ["@@qiaojian_prohibit-turn"] = "禁用伤害牌",

  ["$qiaojian1"] = "曹公奉天子诛暴乱，可谓顺道矣。",
  ["$qiaojian2"] = "袁氏驱胡虏以凌中国，可谓逆德矣。",
}

qiaojian:addEffect("active", {
  anim_type = "control",
  prompt = "#qiaojian",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      not table.contains(player:getTableMark("qiaojian-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "qiaojian-phase", target)
    local result = room:askToJointCards(player, {
      players = { player, target },
      min_num = 1,
      max_num = 999,
      cancelable = false,
      skill_name = qiaojian.name,
      prompt = "#qiaojian-discard",
      will_throw = true,
    })
    local moves = {}
    local num = { 0, 0 }
    for _, p in ipairs({ player, target }) do
      local cards = result[p] or {}
      if #cards > 0 then
        for _, id in ipairs(cards) do
          if p == player then
            num[1] = num[1] + Fk:getCardById(id).number
          else
            num[2] = num[2] + Fk:getCardById(id).number
          end
        end
        table.insert(moves, {
          ids = cards,
          from = p,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = p,
          skillName = qiaojian.name,
        })
      end
    end
    room:moveCards(table.unpack(moves))
    if not player.dead then
      if num[1] > num[2] then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = qiaojian.name,
        }
        if player.dead or target.dead then return end
        local choice = room:askToChoice(player, {
          skill_name = qiaojian.name,
          prompt = "#qiaojian-choice::"..target.id,
          choices = { "qiaojian_extra", "qiaojian_prohibit" },
        })
        room:setPlayerMark(target, choice, 1)
      else
        local cards = table.filter(table.connect(result[player] or {}, result[target] or {}), function (id)
          return table.contains(room.discard_pile, id)
        end)
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, qiaojian.name, nil, true, player, "qiaojian-inhand")
        end
      end
    end
  end,
})

qiaojian:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and player:getMark("qiaojian_extra-turn") > 0 then
      if data.card.trueName == "slash" then
        local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          return use.from == player and use.card.trueName == "slash"
        end, Player.HistoryTurn)
        return use_events[1].data == data
      elseif data.card:isCommonTrick() then
        local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          return use.from == player and use.card.type == Card.TypeTrick
        end, Player.HistoryTurn)
        return use_events[1].data == data
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qiaojian.name,
      prompt = "#qiaojian-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function (self, event, target, player, data)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

qiaojian:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("qiaojian_extra") > 0 then
      room:setPlayerMark(player, "qiaojian_extra", 0)
      room:setPlayerMark(player, "qiaojian_extra-turn", 1)
    end
    if player:getMark("qiaojian_prohibit") > 0 then
      room:setPlayerMark(player, "qiaojian_prohibit", 0)
      room:setPlayerMark(player, "@@qiaojian_prohibit-turn", 1)
    end
  end,
})

qiaojian:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    if player:getMark("@@qiaojian_prohibit-turn") > 0 then
      return card.is_damage_card
    end
  end,
})

qiaojian:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("qiaojian-inhand") > 0
  end,
})

return qiaojian
