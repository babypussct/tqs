local anguo = fk.CreateSkill{
  name = "m_ex__anguo",
}

Fk:loadTranslationTable{
  ["m_ex__anguo"] = "安国",
  [":m_ex__anguo"] = "游戏开始时，你令一名其他角色获得“安国”标记；拥有“安国”标记的角色的手牌上限等于其体力上限；"..
    "出牌阶段开始时，若场上有拥有“安国”标记的角色，你可以将“安国”标记移动给一名本局游戏未获得过此标记的角色；"..
    "当你受到伤害时，若场上有拥有“安国”标记的角色、伤害来源没有“安国”标记、此次伤害的伤害值不小于你的体力值，防止此伤害；"..
    "当拥有“安国”标记的角色进入濒死状态时，其移去“安国”标记并将体力值回复至1点，然后你选择："..
    "1.若你的体力值大于1，你失去体力至1点；2.若你的体力上限大于1，你将体力上限减至1。若如此做，其获得1点“护甲”。",

  ["@@m_ex__anguo"] = "安国",
  ["#m_ex__anguo-choose"] = "安国：选择一名角色，令其获得安国标记",
  ["#m_ex__anguo-move"] = "安国：你可以将%dest的角色的安国标记转移给另一名角色",
  ["m_ex__anguo_losehp"] = "失去体力至1点",
  ["m_ex__anguo_losemaxhp"] = "减少体力上限至1点",

  ["$m_ex__anguo1"] = "感文台知遇，自当鞠躬尽瘁，扶其身后之业。",
  ["$m_ex__anguo2"] = "安国定邦，克成东南一统！",
  ["$m_ex__anguo3"] = "孙氏为危难之际，吾当尽力辅之！",
}

anguo:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(anguo.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = room:getOtherPlayers(player, false)
    if #tos == 0 then return false end
    tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = tos,
      skill_name = anguo.name,
      prompt = "#m_ex__anguo-choose",
      cancelable = false,
    })
    room:setPlayerMark(player, "m_ex__anguo_target", tos[1].id)
    room:addTableMark(player, "m_ex__anguo_used_targets", tos[1].id)
    room:setPlayerMark(tos[1], "@@m_ex__anguo", 1)
  end,
})

anguo:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player == target and player.phase == Player.Play and player:hasSkill(anguo.name) then
      local room = player.room
      local anguotarget
      local anguocantrigger = false
      local mark = player:getTableMark("m_ex__anguo_used_targets")
      for _, p in ipairs(room.alive_players) do
        if p.id == player:getMark("m_ex__anguo_target") then
          anguotarget = p
        elseif p ~= player and not table.contains(mark, p.id) then
          anguocantrigger = true
        end
      end
      if anguocantrigger and anguotarget then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("m_ex__anguo_used_targets")
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = table.filter(room.alive_players, function(p)
        return p ~= player and not table.contains(mark, p.id)
      end),
      skill_name = anguo.name,
      prompt = "#m_ex__anguo-choose",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local old_to = room:getPlayerById(player:getMark("m_ex__anguo_target"))
    room:addTableMark(player, "m_ex__anguo_used_targets", to.id)
    room:setPlayerMark(player, "m_ex__anguo_target", to.id)
    room:setPlayerMark(to, "@@m_ex__anguo", 1)
    if table.every(room.alive_players, function (p)
      return p:getMark("m_ex__anguo_target") ~= old_to.id
    end) then
      room:setPlayerMark(old_to, "@@m_ex__anguo", 0)
    end
  end,
})

anguo:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player == data.to and data.damage >= player.hp and player:hasSkill(anguo.name) then
      local anguotarget = player.room:getPlayerById(player:getMark("m_ex__anguo_target"))
      return anguotarget and not anguotarget.dead and anguotarget ~= data.from
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

anguo:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(anguo.name) and player:getMark("m_ex__anguo_target") == target.id and target.hp < 1
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, {tos = { target }})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "m_ex__anguo_target", 0)
    if table.every(room.alive_players, function(p)
      return p:getMark("m_ex__anguo_target") ~= target.id
    end) then
      room:setPlayerMark(target, "@@m_ex__anguo", 0)
    end
    if target.hp < 1 then
      room:recover({
        who = target,
        num = 1 - target.hp,
        recoverBy = player,
        skillName = anguo.name
      })
    end
    if not player.dead then
      local choices = {}
      if player.hp > 1 then
        table.insert(choices, "m_ex__anguo_losehp")
      end
      if player.maxHp > 1 then
        table.insert(choices, "m_ex__anguo_losemaxhp")
      end
      if #choices > 0 then
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = anguo.name,
          all_choices = {"m_ex__anguo_losehp", "m_ex__anguo_losemaxhp"},
        })
        if choice == "m_ex__anguo_losehp" then
          room:loseHp(player, player.hp - 1, anguo.name)
        elseif choice == "m_ex__anguo_losemaxhp" then
          room:changeMaxHp(player, 1 - player.maxHp)
        end
        room:changeShield(target, 1)
      end
    end
  end,
})

anguo:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:getMark("@@m_ex__anguo") > 0 then
      return player.maxHp
    end
  end
})

anguo:addLoseEffect(function(self, player)
  local room = player.room
  local pid = player:getMark("m_ex__anguo_target")
  if pid ~= 0 then
    room:setPlayerMark(player, "m_ex__anguo_target", 0)
    local to = room:getPlayerById(pid)
    if to and to:getMark("@@m_ex__anguo") > 0 and table.every(room.alive_players, function(p)
      return p:getMark("m_ex__anguo_target") ~= pid
    end) then
      room:setPlayerMark(to, "@@m_ex__anguo", 0)
    end
  end
  room:setPlayerMark(player, "m_ex__anguo_used_targets", 0)
end)

return anguo
