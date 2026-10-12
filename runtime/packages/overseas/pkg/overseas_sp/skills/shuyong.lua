local shuyong = fk.CreateSkill {
  name = "os__shuyong",
}

Fk:loadTranslationTable {
  ["os__shuyong"] = "姝勇",
  [":os__shuyong"] = "当你使用或打出【杀】时，你可以获得一名其他角色区域内的一张牌。然后若本轮你以此法获得过其区域里的牌数大于2，其摸一张牌。",

  ["#os__shuyong-choose"] = "姝勇：你可以获得一名其他角色区域内一张牌",
  ["#os__shuyong-to"] = "姝勇：你可以获得 %dest 区域内一张牌",
  ["#os__shuyong-draw"] = "被拿牌后摸牌",

  ["$os__shuyong1"] = "关将军，看我破敌建功！",
  ["$os__shuyong2"] = "来者何人？速速报上名来！",
}

Fk:addTargetTip {
  name = "#os__shuyong-tip",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    local os__shuyongRecord = player:getMark("os__shuyong_record-round")
    os__shuyongRecord = type(os__shuyongRecord) == "table" and os__shuyongRecord or {}
    if (os__shuyongRecord[to_select.id] or 0) < 2 then
      return
    end

    return "#os__shuyong-draw"
  end,
}

---@type TrigSkelSpec<UseCardFunc|RespondCardFunc>
local os__shuyongSpec = {
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
    local tos = {}
    if #targets == 1 then
      if player.room:askToSkillInvoke(player, {
        skill_name = shuyong.name,
        prompt = "#os__shuyong-to::" .. targets[1].id
      }) then
        tos = targets
      end
    else
      tos = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#os__shuyong-choose",
          skill_name = shuyong.name,
        }
      )
    end
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
    local os__shuyongRecord = player:getMark("os__shuyong_record-round")
    os__shuyongRecord = type(os__shuyongRecord) == "table" and os__shuyongRecord or {}
    if
        #room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
          local move = e.data
          return not not table.find(move, function(moveData)
            return moveData.to == player and moveData.skillName == skillName and #moveData.moveInfo > 0
          end)
        end, room.logic:getCurrentEvent().id) > 0
    then
      os__shuyongRecord = os__shuyongRecord or {}
      os__shuyongRecord[to.id] = (os__shuyongRecord[to.id] or 0) + 1
      room:setPlayerMark(player, "os__shuyong_record-round", os__shuyongRecord)
    end

    if to:isAlive() and (os__shuyongRecord[to.id] or 0) > 2 then
      to:drawCards(1, skillName)
    end
  end,
}

shuyong:addEffect(fk.CardUsing, os__shuyongSpec)

shuyong:addEffect(fk.CardResponding, os__shuyongSpec)

return shuyong
