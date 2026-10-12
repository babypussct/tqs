local qingzhengh = fk.CreateSkill {
  name = "qingzhengh",
  max_branches_use_time = {
    ["qingzhengh_draw"] = {
      [Player.HistoryTurn] = 1,
    },
    ["qingzhengh_recover"] = {
      [Player.HistoryTurn] = 1,
    },
    ["qingzhengh_equip"] = {
      [Player.HistoryTurn] = 1,
    },
  }
}

Fk:loadTranslationTable{
  ["qingzhengh"] = "清政",
  [":qingzhengh"] = "每回合每项限一次，当你的体力值、手牌数、装备区牌数变化后，若值为1，你可以选择一项：1.摸X张牌；2.回复X点体力；" ..
  "3.将牌堆中X张装备牌置入你的装备区。若X大于2，此技能视为未发动过且令你的当前手牌无次数限制" ..
  "（X为你的体力值、手牌数、装备区牌数为1的数量）。",

  ["qingzhengh_draw"] = "摸%arg张牌",
  ["qingzhengh_recover"] = "回复%arg点体力",
  ["qingzhengh_equip"] = "将牌堆中%arg张装备牌置入你的装备区",
  ["@@qingzhengh-inhand"] = "清政",

  ["$qingzhengh1"] = "百姓若得绫罗，吾子无裈亦可。",
  ["$qingzhengh2"] = "粥饭维艰，恒念居野之饿殍。",
}

local qingzhenghCanUse = function(player)
  return table.find(
    { "qingzhengh_draw", "qingzhengh_recover", "qingzhengh_equip" },
    function(branch) return qingzhengh:withinBranchTimesLimit(player, branch) end
  )
end

local qingzhenghOnCost = function(self, event, target, player, data)
  local num = 0
  if player.hp == 1 then
    num = num + 1
  end
  if player:getHandcardNum() == 1 then
    num = num + 1
  end
  if #player:getCardIds("e") == 1 then
    num = num + 1
  end

  local allChoices = {
    "qingzhengh_draw:::" .. num,
    "qingzhengh_recover:::" .. num,
    "qingzhengh_equip:::" .. num,
    "Cancel",
  }
  local choices = table.simpleClone(allChoices)
  if not qingzhengh:withinBranchTimesLimit(player, "qingzhengh_draw") then
    table.removeOne(choices, "qingzhengh_draw:::" .. num)
  end
  if not (player:isWounded() and qingzhengh:withinBranchTimesLimit(player, "qingzhengh_recover")) then
    table.removeOne(choices, "qingzhengh_recover:::" .. num)
  end
  if not (player:hasEmptyEquipSlot() and qingzhengh:withinBranchTimesLimit(player, "qingzhengh_equip")) then
    table.removeOne(choices, "qingzhengh_equip:::" .. num)
  end

  if choices[1] == "Cancel" then
    return false
  end

  local choice = player.room:askToChoice(
    player,
    {
      choices = choices,
      skill_name = qingzhengh.name,
      all_choices = allChoices,
    }
  )

  if choice ~= "Cancel" then
    local choiceSplited = choice:split(":::")
    event:setCostData(self, { history_branch = choiceSplited[1], num = choiceSplited[2]  })
    return true
  end
end

local qingzhenghOnUse = function(self, event, target, player, data)
  ---@type string
  local skillName = qingzhengh.name
  local room = player.room
  local choice = event:getCostData(self).history_branch
  ---@type integer
  local num = tonumber(event:getCostData(self).num)

  if num > 2 then
    player:clearSkillHistory(skillName)
  end

  if choice == "qingzhengh_draw" then
    player:drawCards(num, skillName)
  elseif choice == "qingzhengh_recover" then
    room:recover{
      who = player,
      num = num,
      skillName = skillName,
      recoverBy = player,
    }
  else
    local availableEquipments = {}
    local subTypeList = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeEquip then
        local subType = card.sub_type
        if player:hasEmptyEquipSlot(subType) then
          subType = card:getSubtypeString()
          availableEquipments[subType] = availableEquipments[subType] or {}
          table.insert(availableEquipments[subType], id)
          table.insertIfNeed(subTypeList, subType)
        end
      end
    end

    if #subTypeList == 0 then
      return false
    end

    local toPut = {}
    for _ = 1, num do
      if #subTypeList < 1 then
        break
      end

      local subType = table.remove(subTypeList, math.random(1, #subTypeList))
      table.insert(toPut, room:tableRandomPick(availableEquipments[subType]))
    end

    room:moveCardIntoEquip(player, toPut, skillName, false, player)
  end

  if num > 2 then
    table.forEach(player:getCardIds("h"), function (id)
      room:setCardMark(Fk:getCardById(id, true), "@@qingzhengh-inhand", 1)
    end)
  end
end

qingzhengh:addEffect(fk.HpChanged, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.num <= 0 and
      player.hp == 1 and
      player:hasSkill(qingzhengh.name) and
      qingzhenghCanUse(player)
  end,
  on_cost = qingzhenghOnCost,
  on_use = qingzhenghOnUse,
})

qingzhengh:addEffect(fk.HpRecover, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.hp == 1 and
      player:hasSkill(qingzhengh.name) and
      qingzhenghCanUse(player)
  end,
  on_cost = qingzhenghOnCost,
  on_use = qingzhenghOnUse,
})

qingzhengh:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(qingzhengh.name) and qingzhenghCanUse(player)) then
      return false
    end

    if
      player:getHandcardNum() == 1 and
      table.find(data, function(move)
        return
          (
            move.to == player and
            move.toArea == Card.PlayerHand
          ) or
          (
            move.from == player and
            not not table.find(move.moveInfo, function(info)
              return info.fromArea == Card.PlayerHand
            end)
          )
      end)
    then
      return true
    end

    if
      #player:getCardIds("e") == 1 and
      table.find(data, function(move)
        return
          (
            move.to == player and
            move.toArea == Card.PlayerEquip
          ) or
          (
            move.from == player and
            not not table.find(move.moveInfo, function(info)
              return info.fromArea == Card.PlayerEquip
            end)
          )
      end)
    then
      return true
    end
  end,
  on_cost = qingzhenghOnCost,
  on_use = qingzhenghOnUse,
})

qingzhengh:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card:getMark("@@qingzhengh-inhand") > 0 and not data.extraUse
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

qingzhengh:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@qingzhengh-inhand") > 0
  end,
})

return qingzhengh
