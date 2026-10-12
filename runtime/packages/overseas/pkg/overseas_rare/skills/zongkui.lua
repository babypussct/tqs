local osZongkui = fk.CreateSkill {
  name = "os__zongkui"
}

Fk:loadTranslationTable{
  ["os__zongkui"] = "纵傀",
  [":os__zongkui"] = "每轮开始时或回合开始时，你可以令一名没有“傀”的其他角色获得1枚“傀”；"..
  "当有“傀”的角色造成伤害后，若受伤角色没有“傀”且不为你，你可以令来源将所有“傀”交给受伤角色。",

  ["@@os__puppet"] = "傀",
  ["#os__zongkui-ask"] = "纵傀：选择一名其他角色，令其获得一枚“傀”",
  ["#os__zongkui-transfer"] = "纵傀：令%src的“傀”转移给%dest",

  ["$os__zongkui1"] = "不要抵抗，接受我的操纵吧。",
  ["$os__zongkui2"] = "当我的傀儡，你将受益良多。",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@@os__puppet") == 0 and p ~= player
    end)
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__zongkui-ask",
        skill_name = osZongkui.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(event:getCostData(self), "@@os__puppet")
  end,
}

osZongkui:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osZongkui.name) and
      table.find(player.room.alive_players, function(p)
        return p:getMark("@@os__puppet") == 0 and p ~= player
      end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

osZongkui:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osZongkui.name) and
      table.find(player.room.alive_players, function(p)
        return p:getMark("@@os__puppet") == 0 and p ~= player
      end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

osZongkui:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osZongkui.name) and
      data.from and
      data.from:isAlive() and
      data.from:getMark("@@os__puppet") > 0 and
      data.to ~= player and
      data.to:isAlive() and
      data.to:getMark("@@os__puppet") == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = osZongkui.name,
      prompt = "#os__zongkui-transfer:"..data.from.id..":"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.from, data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(data.from, "@@os__puppet", 0)
    room:setPlayerMark(data.to, "@@os__puppet", 1)
  end,
})

osZongkui:addLoseEffect(function(self, player, is_death)
  local room = player.room
  if table.every(room.alive_players, function(p)
    return not p:hasSkill(osZongkui.name, true)
  end) then
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@@os__puppet", 0)
    end
  end
end)

return osZongkui
