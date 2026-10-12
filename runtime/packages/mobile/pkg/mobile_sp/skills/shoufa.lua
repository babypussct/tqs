local shoufa = fk.CreateSkill{
  name = "shoufa",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "shoufa_1v2"
    else
      return "shoufa_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["shoufa"] = "兽法",
  [":shoufa"] = "当你每回合首次造成伤害后，你可以选择你距离2以内的一名角色；每回合限五次，当你受到伤害后，" ..
  "你可以选择与你距离大于1的一名角色（若为斗地主，则上述距离改为你距离1以内和与你距离不小于1），其随机执行一种效果：<br>" ..
  "豹，其受到1点无来源伤害；<br>鹰，你随机获得其一张牌；<br>熊，你随机弃置其装备区里的一张牌；<br>兔，其摸一张牌。",

  [":shoufa_1v2"] = "当你每回合首次造成伤害后，你可以选择你距离1以内的一名角色；每回合限五次，当你受到伤害后，" ..
  "你可以选择与你距离不小于1的一名角色，其随机执行一种效果：<br>" ..
  "豹，其受到1点无来源伤害；<br>鹰，你随机获得其一张牌；<br>熊，你随机弃置其装备区里的一张牌；<br>兔，其摸一张牌。",
  [":shoufa_role_mode"] = "当你每回合首次造成伤害后，你可以选择你距离2以内的一名角色；每回合限五次，当你受到伤害后，" ..
  "你可以选择与你距离大于1的一名角色，其随机执行一种效果：<br>" ..
  "豹，其受到1点无来源伤害；<br>鹰，你随机获得其一张牌；<br>熊，你随机弃置其装备区里的一张牌；<br>兔，其摸一张牌。",

  ["#shoufa-choose"] = "兽法：选择一名角色令其执行随机野兽效果",
  ["shoufa_bao"] = "豹",
  ["shoufa_ying"] = "鹰",
  ["shoufa_xiong"] = "熊",
  ["shoufa_tu"] = "兔",

  ["$shoufa1"] = "毒蛇恶蝎，奉旨而行！",
  ["$shoufa2"] = "虎豹豺狼，皆听我令！",
}

local shoufaOnUse = function(self, event, target, player, data)
  local room = player.room
  local to = event:getCostData(self).tos[1]
  local beasts = { "shoufa_bao", "shoufa_ying", "shoufa_xiong", "shoufa_tu" }
  local availableBeasts = table.simpleClone(beasts)

  if to == player then
    availableBeasts = { "shoufa_tu" }
  else
    if to:isNude() then
      table.removeOne(availableBeasts, "shoufa_ying")
    end
    if #to:getCardIds("e") == 0 then
      table.removeOne(availableBeasts, "shoufa_xiong")
    end
  end

  local beast = player:getMark("@zhoulin") ~= 0 and player:getMark("@zhoulin") or room:tableRandomPick(availableBeasts)

  if beast == beasts[1] then
    room:damage{
      to = to,
      damage = 1,
      skillName = shoufa.name,
    }
  elseif beast == beasts[2] then
    if to == player then
      if #player:getCardIds("e") > 0 then
        room:obtainCard(player, room:tableRandomPick(player:getCardIds("e")), true, fk.ReasonPrey, player)
      end
    elseif not to:isNude() then
      room:obtainCard(player, room:tableRandomPick(to:getCardIds("he")), false, fk.ReasonPrey, player)
    end
  elseif beast == beasts[3] then
    room:throwCard(room:tableRandomPick(to:getCardIds("e")), shoufa.name, to, player)
  else
    to:drawCards(1, shoufa.name)
  end
end

shoufa:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(shoufa.name) then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player
      end)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:distanceTo(player) < (room:isGameMode("1v2_mode") and 2 or 3)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = shoufa.name,
      prompt = "#shoufa-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = shoufaOnUse,
})

shoufa:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shoufa.name) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) < 5 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:distanceTo(player) > (player.room:isGameMode("1v2_mode") and 0 or 1)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:distanceTo(player) > (room:isGameMode("1v2_mode") and 0 or 1)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = shoufa.name,
      prompt = "#shoufa-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = shoufaOnUse,
})

return shoufa
