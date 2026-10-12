local shuyong = fk.CreateSkill {
  name = "shuyong",
}

Fk:loadTranslationTable {
  ["shuyong"] = "姝勇",
  [":shuyong"] = "当你使用或打出【杀】时，你可以获得一名其他角色区域内的一张牌。然后若本轮你以此法获得过其区域里的牌数大于1，其摸一张牌。",

  ["#shuyong-choose"] = "姝勇：你可以获得一名其他角色区域内一张牌，若如此做，其摸一张牌",
  ["#shuyong-draw"] = "被拿牌后摸牌",

  ["$shuyong1"] = "我的武艺，可是关将军亲传哦！",
  ["$shuyong2"] = "让你看看这招如何！",
}

Fk:addTargetTip {
  name = "#shuyong-tip",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    local shuyongRecord = player:getMark("shuyong_record-round")
    shuyongRecord = type(shuyongRecord) == "table" and shuyongRecord or {}
    if (shuyongRecord[to_select.id] or 0) < 1 then
      return
    end

    return "#shuyong-draw"
  end,
}

local shuyongSpec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
        target == player and
        player:hasSkill(shuyong.name) and
        data.card.trueName == "slash" and
        table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isAllNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isAllNude()
    end)
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#shuyong-choose",
        skill_name = shuyong.name,
        target_tip_name = "#shuyong-tip",
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = shuyong.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, { target = to, flag = "hej", skill_name = skillName })
    room:obtainCard(player, id, false, fk.ReasonPrey, player, skillName)
    local shuyongRecord = player:getMark("shuyong_record-round")
    shuyongRecord = type(shuyongRecord) == "table" and shuyongRecord or {}
    if
        #room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
          local move = e.data
          return not not table.find(move, function(moveData)
            return moveData.to == player and moveData.skillName == skillName and #moveData.moveInfo > 0
          end)
        end, room.logic:getCurrentEvent().id) > 0
    then
      shuyongRecord = shuyongRecord or {}
      shuyongRecord[to.id] = (shuyongRecord[to.id] or 0) + 1
      room:setPlayerMark(player, "shuyong_record-round", shuyongRecord)
    end

    if to:isAlive() and (shuyongRecord[to.id] or 0) > 1 then
      to:drawCards(1, skillName)
    end
  end,
}

shuyong:addEffect(fk.CardUsing, shuyongSpec)

shuyong:addEffect(fk.CardResponding, shuyongSpec)

return shuyong
