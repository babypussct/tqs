local shuyin = fk.CreateSkill {
  name = "os__shuyin",
}

Fk:loadTranslationTable {
  ["os__shuyin"] = "姝音",
  [":os__shuyin"] = "你每回合首次使用一种花色的牌后，你可以摸一张牌并选择一项：" ..
  "1.你下次使用的牌（装备牌与延时锦囊牌除外）额外结算X次（X为“芳妍”牌的花色数-1且至少为1）；" ..
  "2.令一名角色将一张牌作为“芳妍”牌置于你的武将牌上。",

  ["os__shuyin_extra"] = "下一张牌额外结算",
  ["os__shuyin_put"] = "令一名角色将一张牌置为“芳妍”",
  ["#os__shuyin-ask"] = "姝音：你可以发动“姝音”，选择一项",
  ["@@os__shuyin_extra"] = "姝音额外",
  ["#os__shuyin-put"] = "姝音：将一张牌置于 %src 的武将牌上",
  ["@os__shuyin-turn"] = "姝音",

  ["$os__shuyin1"] = "江东礼乐乐土，岂是兵戈所及？",
  ["$os__shuyin2"] = "礼乐声声入耳，太平口口不绝！",
}

shuyin:addAuxActiveSkill("os__shuyin_choose", {
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = UI.OptionBox { options = { "os__shuyin_extra", "os__shuyin_put" }, direct_send = true },
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    return #selected_targets == 0 and { "os__shuyin_extra" } or { "os__shuyin_put" }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0
  end,
})

shuyin:addEffect(fk.CardUseFinished, {
  can_trigger = function (self, event, target, player, data)
    if not (player == target and player:hasSkill(shuyin.name)) then return end
    local room = player.room
    local logic = room.logic
    local use_e = logic:getCurrentEvent()
    local suit = data.card.suit
    local mark = player:getTableMark("os__shuyin_event-turn")
    if not mark[suit] then -- 当前花色有记录就直接判断，否则遍历历史回合事件记录
      local suits = player:getTableMark("@os__shuyin-turn")
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        local s = use.card.suit
        if use.from == data.from and s ~= Card.NoSuit then
          if not mark[s] then -- 没有该花色的第一个事件则记录
            mark[s] = e.id
            table.insert(suits, use.card:getSuitString(true)) -- 可视化
            return s == suit -- 若是当前花色，则停止遍历
          end
        end
      end, Player.HistoryTurn)
      room:setPlayerMark(player, "@os__shuyin-turn", suits)
      room:setPlayerMark(player, "os__shuyin_event-turn", mark)
    end
    return mark[suit] == use_e.id
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(1, shuyin.name)
    if player.dead then return end
    local _, res = room:askToUseActiveSkill(player, {
      skill_name = "os__shuyin_choose",
      prompt = "#os__shuyin-ask",
      cancelable = false,
    })
    local choice, to
    if res then
      choice, to = res.interaction, res.targets[1]
    else
      choice, to = "os__shuyin_extra", player
    end
    if choice == "os__shuyin_extra" then
      room:addPlayerMark(player, "@@os__shuyin_extra")
    else
      local cards = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        cancelable = true,
        include_equip = true,
        pattern = ".",
        skill_name = shuyin.name,
        prompt = "#os__shuyin-put:" .. player.id,
      })
      if #cards > 0 then
        player:addToPile("os__fangyan", cards, true, shuyin.name, player)
      end
    end
  end,
})

shuyin:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@os__shuyin_extra") > 0 and
        (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local suits = {}
    for _, id in ipairs(player:getPile("os__fangyan")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    data.additionalEffect = (data.additionalEffect or 0) + math.max(#suits - 1, 1)
    player.room:setPlayerMark(player, "@@os__shuyin_extra", 0)
  end,
})

return shuyin
