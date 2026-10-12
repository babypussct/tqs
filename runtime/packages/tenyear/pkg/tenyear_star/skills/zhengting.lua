local zhengting = fk.CreateSkill{
  name = "zhengting",
}

Fk:loadTranslationTable{
  ["zhengting"] = "正听",
  [":zhengting"] = "出牌阶段限一次，你可以选择一名其他角色，你与其互相观看对方手牌，然后你选择一项："..
  "1.你与其分别将手牌弃置至每种花色仅剩一张；2.你与其分别将手牌中没有的花色各摸一张。",

  ["#zhengting"] = "正听：与一名角色互相观看手牌，然后将手牌弃或摸至每种花色各一张",
  ["#zhengting-choice"] = "正听：选择一项令双方执行",
  ["zhengting_discard"] = "将手牌弃至每种花色仅剩一张",
  ["zhengting_draw"] = "将手牌中没有的花色各摸一张",
  ["#zhengting-discard"] = "正听：请将手牌弃至每种花色仅剩一张",

  ["$zhengting1"] = "沉溺声色，汉室何日可兴！",
  ["$zhengting2"] = "荒废政事，祖宗基业谁承！",
}

local getCount = function (player)
  local ret = {}
  for _, id in ipairs(player:getCardIds("h")) do
    local suit = Fk:getCardById(id):getSuitString()
    ret[suit] = ret[suit] or {}
    table.insert(ret[suit], id)
  end
  return ret
end

zhengting:addAuxActiveSkill("zhengting_active", {
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select) and
      #getCount(player)[Fk:getCardById(to_select):getSuitString()] > 1 and
      table.find(getCount(player)[Fk:getCardById(to_select):getSuitString()], function (id)
        return id ~= to_select and not table.contains(selected, id)
      end)
  end,
  feasible = function (self, player, selected, selected_cards)
    local ret = getCount(player)
    for suit, _ in pairs(ret) do
      for _, id in ipairs(selected_cards) do
        table.removeOne(ret[suit], id)
      end
    end
    for _, ids in pairs(ret) do
      if #ids > 1 and table.find(ids, function (id)
        return not player:prohibitDiscard(id)
      end) then
        return false
      end
    end
    return true
  end,
})

zhengting:addEffect("active", {
  anim_type = "control",
  prompt = "#zhengting",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(zhengting.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local tos = {}
    if not target:isKongcheng() then
      table.insert(tos, player)
    end
    if not player:isKongcheng() then
      table.insert(tos, target)
    end
    if #tos > 0 then
      local req = Request:new(tos, "AskForCardsAndChoice")
      req.focus_text = zhengting.name
      req.focus_players = tos
      if table.contains(tos, player) then
        req:setData(player, {
          cards = target:getCardIds("h"),
          choices = { "OK" },
          prompt = "$ViewCards",
          min = 0,
          max = 0,
        })
      end
      if table.contains(tos, target) then
        req:setData(target, {
          cards = player:getCardIds("h"),
          choices = { "OK" },
          prompt = "$ViewCards",
          min = 0,
          max = 0,
        })
      end
      req:ask()
    end
    local choice = room:askToChoice(player, {
      skill_name = zhengting.name,
      prompt = "#zhengting-choice",
      choices = { "zhengting_discard", "zhengting_draw" },
    })
    if choice == "zhengting_discard" then
      for _, p in ipairs({ player, target }) do
        local count = {}
        for _, id in ipairs(p:getCardIds("h")) do
          local suit = Fk:getCardById(id):getSuitString()
          count[suit] = count[suit] or {}
          table.insert(count[suit], id)
        end
        local yes = false
        for _, ids in pairs(count) do
          if #ids > 1 and table.find(ids, function (id)
            return not p:prohibitDiscard(id)
          end) then
            yes = true
            break
          end
        end
        if yes then
          local success, dat = room:askToUseActiveSkill(p, {
            skill_name = "zhengting_active",
            prompt = "#zhengting-discard",
            cancelable = false,
          })
          if not (success and dat) then
            dat = {}
            dat.cards = {}
            for _, ids in pairs(count) do
              if #ids > 1 then
                local others = table.filter(ids, function (id)
                  return p:prohibitDiscard(id)
                end)
                if #others > 0 then
                  for _, id in ipairs(ids) do
                    if not table.contains(others, id) then
                      table.insert(dat.cards, id)
                    end
                  end
                else
                  table.removeOne(ids, room:tableRandomPick(ids))
                  table.insertTable(dat.cards, ids)
                end
              end
            end
          end
          if #dat.cards > 0 then
            room:throwCard(dat.cards, zhengting.name, p, p)
          end
        end
      end
    else
      for _, p in ipairs({ player, target }) do
        if not p.dead then
          local suits = { Card.Spade, Card.Club, Card.Heart, Card.Diamond }
          for _, id in ipairs(p:getCardIds("h")) do
            table.removeOne(suits, Fk:getCardById(id).suit)
          end
          if #suits > 0 then
            local cards = {}
            --从牌堆顶开始检索
            local dp = room.draw_pile
            for _, id in ipairs(dp) do
              if table.removeOne(suits, Fk:getCardById(id).suit) then
                table.insert(cards, id)
                if #suits == 0 then break end
              end
            end
            if #cards > 0 then
              room:moveCardTo(cards, Card.PlayerHand, p, fk.ReasonDraw, zhengting.name, nil, false, p)
            end
          end
        end
      end
    end
  end,
})

return zhengting
