local xianlue = fk.CreateSkill {
  name = "xianluez",
  max_branches_use_time = function(self, player)
    local ret = {}
    for _, to in ipairs(Fk:currentRoom().players) do
      ret[tostring(to.id)] = {
        [Player.HistoryPhase] = 1,
      }
    end
    return ret
  end
}

Fk:loadTranslationTable{
  ["xianluez"] = "显略",
  [":xianluez"] = "出牌阶段每名角色限一次，你可以观看本回合受到过伤害或失去过牌的一名其他角色的手牌并记录其中所有牌的点数。"..
  "当本次记录点数的数量超过3、6、9时，你摸三张牌。"..
  "若已因此记录了所有点数，则清除记录且〖豪贤〗视为未发动过。"..
  "你每次造成伤害令其他角色进入濒死状态后，本次记录触发后续的点数减少3个。",

  ["#xianluez"] = "显略：观看一名角色的手牌并记录其中所有牌的点数",
  ["@[xianluez]"] = "显略",
  ["@@xianluez-inhand"] = "显略",

  ["$xianluez1"] = "酒入肝肠，计上心来，阵前诈醉，帐后藏兵！",
  ["$xianluez2"] = "恃勇力，识天时，胸中甲兵不逊丈八蛇矛。",
}

Fk:addQmlMark{
  name = "xianluez",
  how_to_show = function(name, value, p)
    local x = 0
    if type(value) == "table" then
      x = #value
    end
    return tostring(x).."/"..tostring(math.max(13-p:getMark("xianluez_decrease"), 0))
  end,
  qml = function(name, value, player)
    return {
      url = "packages/tenyear/qml/GeyuanBox.qml",
      prop = {
        name = name,
        all = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" },
        ok = table.map(value, function(number)
          return Card:getNumberStr(number)
        end),
      }
    }
  end,
}

xianlue:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@[xianluez]", {})
end)

xianlue:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "@[xianluez]", 0)
  room:setPlayerMark(player, "xianluez_decrease", 0)
  room:setPlayerMark(player, "xianluez-turn", 0)
  room:setPlayerMark(player, "xianluez_times", 0)
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@xianluez-inhand", 0)
  end
end)

xianlue:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#xianluez",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      xianlue:withinBranchTimesLimit(player, tostring(to_select.id), Player.HistoryPhase) and
      table.contains(player:getTableMark("xianluez-turn"), to_select) and not to_select:isKongcheng()
  end,
  history_branch = function(self, player, data)
    return tostring(data.tos[1].id)
  end,
  on_use = function(self, room, effect)
    -- 获取技能使用者与目标角色
    local player, target = effect.from, effect.tos[1]
    if not target or not target:isAlive() then return end

    -- 预存手牌ID，避免重复调用getCardIds
    local player_hand = player:getCardIds("h")
    local target_hand = target:getCardIds("h")

    -- 获取已记录点数、原长度、触发上限
    local numbers = player:getTableMark("@[xianluez]")
    local oldLen, max = #numbers, 12 - player:getMark("xianluez_decrease")

    -- 将目标手牌点数去重加入记录
    for _, id in ipairs(target_hand) do
      table.insertIfNeed(numbers, Fk:getCardById(id).number)
    end
    local newLen = #numbers

    -- 摸牌计算：跨过3/6/9各摸3张
    local draw = 0
    for _, v in ipairs{ 3, 6, 9 } do
      if oldLen <= v and v < newLen then draw = draw +3 end
    end

    -- 超过上限 → 触发重置爆发
    if newLen > max then
      room:setPlayerMark(player, "xianluez_times", player:getMark("xianluez_times")+1)
      room:setPlayerMark(player, "xianluez_decrease", 0)
      room:setPlayerMark(player, "@[xianluez]", {})
      -- 使用预存的手牌清空标记
      for _, id in ipairs(player_hand) do
        room:setCardMark(Fk:getCardById(id), "@@xianluez-inhand", 0)
      end
      player:clearSkillHistory("haoxian")

    -- 新增点数 → 更新记录与标记
    elseif newLen > oldLen then
      room:setPlayerMark(player, "@[xianluez]", numbers)
      -- 使用预存手牌同步标记
      for _, id in ipairs(player_hand) do
        local c = Fk:getCardById(id, true)
        room:setCardMark(c, "@@xianluez-inhand", table.contains(numbers, c.number) and 1 or 0)
      end
    end

    -- 观看目标手牌（使用预存）
    room:viewCards(player, {
      cards = target_hand,
      skill_name = xianlue.name,
      prompt = "$ViewCardsFrom:"..target.id
    })

    -- 执行摸牌
    if draw > 0 then
      player:drawCards(draw, xianlue.name)
    end
  end,
})

xianlue:addEffect(fk.EnterDying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    --回合内才能发动（不知道是不是bug），而且似乎还有其他限制条件，有的时候不会发动，很诡异，找不到规律
    return player:hasSkill(xianlue.name) and player.room:getCurrent() == player and
      data.who ~= player and data.damage and data.damage.from == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xianluez_decrease", 3)
  end,
})

--已记录点数的手牌标记（UI only）
xianlue:addEffect(fk.AfterCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@[xianluez]")
    if #mark > 0 then
      for _, id in ipairs(player:getCardIds("h")) do
        local card = Fk:getCardById(id, true)
        if card:getMark("@@xianluez-inhand") > 0 then
          if not table.contains(mark, card.number) then
            room:setCardMark(card, "@@xianluez-inhand", 0)
          end
        elseif table.contains(mark, card.number) then
          room:setCardMark(card, "@@xianluez-inhand", 1)
        end
      end
    end
  end
})

--线上后面这些都是靠武张飞发动技能来记录的（会入自选），十分离谱
xianlue:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xianlue.name) and player.room:getCurrent() == player and not target.dead and not
      table.contains(player:getTableMark("xianluez-turn"), target)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "xianluez-turn", target)
  end
})

--严格回合内（一号位不算滕芳兰拆牌）
xianlue:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(xianlue.name) and player.room:getCurrent() == player then
      local mark = player:getTableMark("xianluez-turn")
      local playerAreas = { Player.Hand, Player.Equip }
      local targets = {}
      for _, move in ipairs(data) do
        if move.from and not table.contains(mark, move.from) and not table.contains(targets, move.from) and
          (move.to ~= move.from or not table.contains(playerAreas, move.toArea)) then
          --经典因使用装备牌而失去牌不算
          if move.moveReason ~= fk.ReasonUse then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(playerAreas, info.fromArea) then
                table.insert(targets, move.from)
                break
              end
            end
          else
            local parent_event = player.room.logic:getCurrentEvent().parent
            if parent_event ~= nil then
              if parent_event.event == GameEvent.UseCard then
                local use = parent_event.data
                if use.from ~= move.from or use.card.type ~= Card.TypeEquip then
                  for _, info in ipairs(move.moveInfo) do
                    if table.contains(playerAreas, info.fromArea) then
                      table.insert(targets, move.from)
                      break
                    end
                  end
                end
              end
            end
          end
        end
      end
      if #targets > 0 then
        event:setCostData(self, { extra_data = targets })
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getTableMark("xianluez-turn")
    table.insertTable(mark, event:getCostData(self).extra_data)
    player.room:setPlayerMark(player, "xianluez-turn", mark)
  end
})

return xianlue
