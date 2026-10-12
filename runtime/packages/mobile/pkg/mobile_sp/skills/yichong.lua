local yichong = fk.CreateSkill {
  name = "yichong",
}

Fk:loadTranslationTable{
  ["yichong"] = "易宠",
  [":yichong"] = "准备阶段，你可以选择一名其他角色并指定一种花色，获得其所有该花色的装备和一张该花色的手牌，并令其获得“雀”标记直到你下个回合开始"..
  "（若场上已有“雀”标记则转移给该角色）。拥有“雀”标记的角色获得你指定花色的牌时，你获得此牌（你至多因此“雀”标记获得一张牌）。",

  ["#yichong-choose"] = "你可以发动 易宠，选择一名其他角色，获得其所有该花色的装备区里的牌和一张该花色的手牌",
  ["@yichong_que"] = "雀",
  ["@yichong"] = "易宠",

  ["$yichong1"] = "处椒房之尊，得陛下隆宠！",
  ["$yichong2"] = "三千宠爱？当聚于我一身！",
}

yichong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yichong.name) and target == player and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(
      player,
      {
        targets = player.room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#yichong-choose",
        skill_name = yichong.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yichong.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local suits = { "log_spade", "log_club", "log_heart", "log_diamond" }
    local choice = room:askToChoice(player, { choices = suits, skill_name = skillName })

    local cards = table.filter(to:getCardIds("e"), function (id)
      return Fk:getCardById(id):getSuitString(true) == choice
    end)
    local hand = to:getCardIds("h")
    for _, id in ipairs(hand) do
      if Fk:getCardById(id):getSuitString(true) == choice then
        table.insert(cards, id)
        break
      end
    end
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

      local mark2 = to:getTableMark("@yichong_que")
      table.insert(mark2, choice)
      room:setPlayerMark(to, "@yichong_que", mark2)
      room:setPlayerMark(player, "yichong_target", { to.id, choice })
      room:setPlayerMark(player, "@yichong", { 0 })
    end
  end,
})

yichong:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yichong.name) then
      return false
    end

    local mark = player:getMark("@yichong")
    if type(mark) ~= "table" or mark[1] > 0 then return false end
    mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end

    local room = player.room
    local to = room:getPlayerById(mark[1])
    if to == nil or not to:isAlive() then return false end
    for _, move in ipairs(data) do
      if move.to == to and move.toArea == Card.PlayerHand then
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
    local mark = player:getMark("@yichong")
    if type(mark) ~= "table" or mark[1] > 0 then return false end
    local x = 1 - mark[1]
    mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local to = room:getPlayerById(mark[1])
    if to == nil or not to:isAlive() then return false end

    local cards = {}
    for _, move in ipairs(data) do
      if move.to == to and move.toArea == Card.PlayerHand then
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
    elseif #cards > x then
      cards = room:tableRandomPick(cards, x)
    end
    room:setPlayerMark(player, "@yichong", { 1 - x + #cards })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, yichong.name, nil, true, player)
  end,
})

local yichongClearSpec = {
  can_refresh = function(self, event, target, player, data)
    return player == target and type(player:getMark("yichong_target")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("yichong_target")
    local to = room:getPlayerById(mark[1])
    local mark2 = to:getMark("@yichong_que")
    if type(mark2) == "table" then
      table.removeOne(mark2, mark[2])
      room:setPlayerMark(to, "@yichong_que", #mark2 > 0 and mark2 or 0)
    end
    room:setPlayerMark(player, "yichong_target", 0)
    room:setPlayerMark(player, "@yichong", 0)
  end,
}

yichong:addEffect(fk.TurnStart, yichongClearSpec)

yichong:addLoseEffect(function(self, player)
  if yichongClearSpec.can_refresh(self, nil, player, player) then
    yichongClearSpec.on_refresh(self, nil, nil, player)
  end
end)

return yichong
