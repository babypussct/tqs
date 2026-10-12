local osYichong = fk.CreateSkill {
  name = "os__yichong"
}

Fk:loadTranslationTable{
  ["os__yichong"] = "易宠",
  [":os__yichong"] = "准备阶段，你可选择一名其他角色并选择一种花色，获得其所有该花色的牌，并令其获得“雀”标记直到你下个回合开始" ..
  "（若场上已有“雀”标记则转移给该角色）。拥有“雀”标记的角色获得下一张你指定花色的牌时，你获得之。",

  ["@os__yichong"] = "易宠",
  ["#os__yichong-choose"] = "你可以发动 易宠，选择一名其他角色和一种花色，获得其该花色的所有牌",

  ["$os__yichong1"] = "弱水三千，唯妾独讨陛下之心。",
  ["$os__yichong2"] = "陛下恩宠如此，妾自堪当此位。",
}

osYichong:addAuxActiveSkill("os__yichong_choose", {
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and to_select ~= player
  end,
  interaction = function(self, player)
    return UI.OptionBox { options = { "log_spade", "log_club", "log_heart", "log_diamond" }, direct_send = true }
  end,
})

osYichong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(osYichong.name)
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "os__yichong_choose",
      prompt = "#os__yichong-choose",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osYichong.name
    local room = player.room
    player:broadcastSkillInvoke("yichong")
    local dat = event:getCostData(self)
    local to = dat.tos[1]
    local choice = dat.choice
    local cards = table.filter(to:getCardIds("he"), function (id)
      return Fk:getCardById(id):getSuitString(true) == choice
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, skillName, nil, true, player)
    end
    if player:isAlive() and to:isAlive() then
      local mark = player:getMark("yichong_target")
      if type(mark) == "table" then
        local orig_to = room:getPlayerById(mark[1])
        local mark2 = orig_to:getMark("@yichong_que")
        if type(mark2) == "table" then
          table.removeOne(mark2, mark[2])
          room:setPlayerMark(orig_to, "@yichong_que", #mark2 > 0 and mark2 or 0)
        end
      end
      room:addTableMark(to, "@yichong_que", choice)
      room:setPlayerMark(player, "yichong_target", { to.id, choice })
      room:setPlayerMark(player, "@os__yichong", { 0 })
    end
  end,
})

osYichong:addEffect(fk.AfterCardsMove, {
  is_delay_effect = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osYichong.name) then
      return false
    end

    local mark = player:getMark("@os__yichong")
    if type(mark) ~= "table" or mark[1] > 0 then
      return false
    end

    mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then
      return false
    end

    local room = player.room
    local to = room:getPlayerById(mark[1])
    if to == nil or not to:isAlive() then
      return false
    end

    for _, move in ipairs(data) do
      if move.to and move.to.id == mark[1] and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if
            room:getCardArea(id) == Card.PlayerHand and
            room:getCardOwner(id) == to and
            Fk:getCardById(id):getSuitString(true) == mark[2]
          then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@os__yichong")
    if type(mark) ~= "table" or mark[1] > 0 then
      return false
    end

    local x = 1 - mark[1]
    mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then
      return false
    end

    local to = room:getPlayerById(mark[1])
    if to == nil or not to:isAlive() then
      return false
    end

    local cards = {}
    for _, move in ipairs(data) do
      if move.to and move.to.id == mark[1] and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if
            room:getCardArea(id) == Card.PlayerHand and
            room:getCardOwner(id) == to and
            Fk:getCardById(id):getSuitString(true) == mark[2]
          then
            table.insert(cards, id)
          end
        end
      end
    end
    if #cards == 0 then
      return false
    elseif
      #cards > x then cards = room:tableRandomPick(cards, x)
    end
    room:setPlayerMark(player, "@os__yichong", { 1 - x + #cards })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, osYichong.name, nil, true, player)
  end,
})

local osYichongClear = function(self, player)
  local room = player.room
  local mark = player:getMark("yichong_target")
  if type(player:getMark("yichong_target")) ~= "table" then
    return
  end

  local to = room:getPlayerById(mark[1])
  local mark2 = to:getMark("@yichong_que")
  if type(mark2) == "table" then
    table.removeOne(mark2, mark[2])
    room:setPlayerMark(to, "@yichong_que", #mark2 > 0 and mark2 or 0)
  end
  room:setPlayerMark(player, "yichong_target", 0)
  room:setPlayerMark(player, "@os__yichong", 0)
end

osYichong:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player == target and type(player:getMark("yichong_target")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    osYichongClear(self, player)
  end,
})

osYichong:addLoseEffect(osYichongClear)

return osYichong
