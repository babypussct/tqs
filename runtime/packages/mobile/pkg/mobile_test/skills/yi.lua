
local yi = fk.CreateSkill {
  name = "mobile__natu_yi",
}

Fk:loadTranslationTable{
  ["mobile__natu_yi"] = "义",
  [":mobile__natu_yi"] = "出牌阶段限一次，你可以令至多两名角色交给你一张牌，然后你选择一项：<br>"..
  "1.将这些牌当【杀】对其中一名角色使用（不计入次数限制且无距离次数限制），此【杀】结算中，其不能使用与此【杀】转化前的牌相同颜色的手牌；<br>"..
  "2.将这些牌分配给未成为目标的角色，其使用因此获得的黑色牌指定其他角色为目标后，目标本回合非锁定技失效。",

  ["#mobile__natu_yi"] = "义：令至多两名角色交给你一张牌，然后你选择一项",
  ["#mobile__natu_yi-ask"] = "义：请交给 %src 一张牌",
  ["mobile__natu_yi_slash"] = "将这些牌当【杀】对其中一名角色使用",
  ["mobile__natu_yi_give"] = "分配这些牌",
  ["#mobile__natu_yi-slash"] = "义：将这些牌当【杀】对其中一名角色使用，目标不能使用被转化的颜色的手牌",
  ["#mobile__natu_yi-give"] = "义：请分配这些牌，使用其中的黑色牌会令目标非锁定技失效",
  ["@@mobile__natu_yi-inhand"] = "义",

  ["$mobile__natu_yi1"] = "在我种花家，自古以义为先。",
  ["$mobile__natu_yi2"] = "愿这大义，流传千古。",
}

yi:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile__natu_yi",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  can_use = function (self, player)
    return player:usedSkillTimes(yi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < 2 and not to_select:isNude() and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    local cards = {}
    for _, p in ipairs(effect.tos) do
      if not p:isNude() then
        local card = room:askToCards(p, {
          skill_name = yi.name,
          min_num = 1,
          max_num = 1,
          include_equip = true,
          prompt = "#mobile__natu_yi-ask:" .. player.id,
          cancelable = false,
        })
        table.insertIfNeed(cards, card[1])
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, yi.name, nil, false, p)
        if player.dead then return end
      end
    end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    local choices = { "mobile__natu_yi_give" }
    local slash = Fk:cloneCard("slash")
    slash:addSubcards(cards)
    slash.skillName = yi.name
    if table.find(effect.tos, function (p)
      return not p.dead and player:canUseTo(slash, p, { bypass_distances = true, bypass_times = true })
    end) then
      table.insert(choices, 1, "mobile__natu_yi_slash")
    end
    local choice = room:askToChoice(player, {
      skill_name = yi.name,
      choices = choices,
    })
    if choice == "mobile__natu_yi_slash" then
      local use = room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = yi.name,
        prompt = "#mobile__natu_yi-slash",
        cancelable = false,
        skip = true,
        subcards = cards,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          extraUse = true,
          exclusive_targets = table.map(effect.tos, Util.IdMapper),
        }
      })
      if use then
        local mark = {}
        for _, id in ipairs(cards) do
          table.insertIfNeed(mark, Fk:getCardById(id).color)
        end
        for _, p in ipairs(use.tos) do
          room:setPlayerMark(p, "mobile__natu_yi-phase", mark)
        end
        room:useCard(use)
      end
    else
      local result = room:askToYiji(player, {
        cards = cards,
        targets = table.filter(room.alive_players, function (p)
          return not table.contains(effect.tos, p)
        end),
        skill_name = yi.name,
        min_num = #cards,
        max_num = #cards,
        prompt = "#mobile__natu_yi-give",
        skip = true,
      })
      local moves = {}
      for id, ids in pairs(result) do
        if #ids > 0 then
          local to = room:getPlayerById(id)
          if to == player then
            for _, c in ipairs(ids) do
              if Fk:getCardById(c).color == Card.Black then
                room:setCardMark(Fk:getCardById(c), "@@mobile__natu_yi-inhand", player)
              end
            end
          else
            table.insert(moves, {
              ids = ids,
              from = player,
              to = to,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonGive,
              skillName = yi.name,
              proposer = player,
              moveVisible = false,
              moveMark = { "@@mobile__natu_yi-inhand", player },
            })
          end
        end
      end
      if next(moves) then
        room:moveCards(table.unpack(moves))
        for _, c in ipairs(cards) do
          if Fk:getCardById(c).color ~= Card.Black then
            room:setCardMark(Fk:getCardById(c), "@@mobile__natu_yi-inhand", 0)
          end
        end
      end
    end
  end,
})

yi:addEffect(fk.TargetSpecified, {
  can_refresh = function (self, event, target, player, data)
    return target == player and
      table.find(data.use:getMark("@@mobile__natu_yi-inhand"), function (mark)
        return mark ~= data.to
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(data.to, "@@chaojue-turn", 1)
    room:addPlayerMark(data.to, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
  end,
})

yi:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
    return table.contains(data.tos, player) and table.contains(data.card.skillNames, yi.name)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "mobile__natu_yi-phase", 0)
  end,
})

yi:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    return player:getMark("mobile__natu_yi-phase") ~= 0 and
    table.find(Card:getIdList(card), function (id)
      return table.contains(player:getCardIds("h"), id) and
        table.contains(player:getMark("mobile__natu_yi-phase"), Fk:getCardById(id).color)
    end)
  end,
})

return yi
