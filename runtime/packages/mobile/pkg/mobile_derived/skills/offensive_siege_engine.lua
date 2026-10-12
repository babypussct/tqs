local skill = fk.CreateSkill {
  name = "#offensive_siege_engine_skill",
  attached_equip = "offensive_siege_engine",
}

Fk:loadTranslationTable{
  ["#offensive_siege_engine_skill"] = "大攻车·进击",
  ["@offensive_siege_engine_durability"] = "进击耐久",
  ["#offensive_siege_engine"] = "大攻车·进击",
  ["#offensive_siege_engine-invoke"] = "大攻车·进击：你可令【大攻车】减1点耐久度，使对 %dest 造成的伤害+%arg",
}

skill:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#offensive_siege_engine-invoke::"..data.to.id..":"..math.min(room:getBanner("RoundCount"), 3)
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@offensive_siege_engine_durability", 1)
    data:changeDamage(math.min(room:getBanner("RoundCount"), 3))
    if player:getMark("@offensive_siege_engine_durability") < 1 then
      local cards = table.filter(player:getCardIds("e"), function(id)
        return Fk:getCardById(id).name == "offensive_siege_engine"
      end)
      room:sendLog{
        type = "#DestructCards",
        card = cards,
      }
      room:moveCards{
        ids = cards,
        from = player,
        toArea = Card.Void,
        skillName = skill.name,
        moveReason = fk.ReasonJustMove,
      }
    end
  end,
})
skill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name, true) and #player:getCardIds("e") > 1 then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerEquip then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "offensive_siege_engine" and
              not player:prohibitDiscard(info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local cards = table.filter(player:getCardIds("e"), function(id)
      return Fk:getCardById(id).name ~= "offensive_siege_engine"
    end)
    player.room:throwCard(cards, skill.name, player, player)
  end,
})
skill:addEffect(fk.BeforeCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name, true) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerEquip then
          return true
        end
        if move.from == player and not table.contains({"quchong", "gamerule_aborted", skill.name}, move.skillName) then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "offensive_siege_engine" and
              info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toVoid = {}
    local toRemoveIndex = {}
    for index, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerEquip then
        move.to = nil
        move.toArea = Card.DiscardPile
      end
      if move.from == player and not table.contains({"quchong", "gamerule_aborted", skill.name}, move.skillName) then
        local newMoveInfos = {}
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "offensive_siege_engine" and info.fromArea == Card.PlayerEquip then
            local durability = player:getMark("@offensive_siege_engine_durability")
            durability = math.max(durability - 1, 0)
            room:setPlayerMark(player, "@offensive_siege_engine_durability", durability)
            if durability < 1 then
              table.insert(toVoid, info)
            end
          else
            table.insert(newMoveInfos, info)
          end
        end

        if #move.moveInfo > #newMoveInfos then
          move.moveInfo = newMoveInfos
          if #newMoveInfos == 0 then
            table.insert(toRemoveIndex, index)
          end
        end
      end
    end

    if #toRemoveIndex > 0 then
      for i, index in ipairs(toRemoveIndex) do
        table.remove(data, index - (i - 1))
      end
    end

    if #toVoid > 0 then
      room:sendLog{
        type = "#DestructCards",
        card = table.map(toVoid, function(info) return info.cardId end)
      }
      local newMoveData = {
        moveInfo = toVoid,
        from = player,
        toArea = Card.Void,
        moveReason = fk.ReasonPut,
        skillName = skill.name,
      }
      table.insert(data, newMoveData)
    end

    if #data == 0 then
      return true
    end
  end,
})
skill:addEffect(fk.BeforeCardsMove, {
  can_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player and move.toArea ~= Card.Void and
        ((move.skillName == "quchong" and move.moveReason == fk.ReasonRecast) or
        move.skillName == "gamerule_aborted" or
        not player:hasSkill(skill.name)) then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "offensive_siege_engine" and info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local to_void = {}
    for _, move in ipairs(data) do
      if move.from == player and move.toArea ~= Card.Void then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if Fk:getCardById(id).name == "offensive_siege_engine" and info.fromArea == Card.PlayerEquip then
            table.insert(to_void, id)
          end
        end
      end
    end
    if #to_void > 0 then
      local room = player.room
      room:setPlayerMark(player, "@offensive_siege_engine_durability", 0)
      for _, id in ipairs(to_void) do
        room:setCardMark(Fk:getCardById(id), "offensive_siege_engine_durability", 0)
        room:setCardMark(Fk:getCardById(id), MarkEnum.DestructOutMyEquip, 1)
      end
    end
  end,
})

return skill
