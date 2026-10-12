---@param room Room
---@param player ServerPlayer
---@param add boolean
---@param isDamage boolean
local function handleZhuihuan(room, player, add, isDamage)
  local mark_name = isDamage and "ty_heg__zhuihuan_damage" or "ty_heg__zhuihuan_discard"
  room:setPlayerMark(player, "@@" .. mark_name, add and 1 or 0)
  -- room:handleAddLoseSkills(player, add and "#" .. mark_name or "-#" .. mark_name, nil, false, true)
end

local zhuihuan = fk.CreateSkill{
  name = "ty_heg__zhuihuan",
}
zhuihuan:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhuihuan.name) and target == player and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = player.room.alive_players,
      min_num = 1, max_num = 2, prompt = "#ty_heg__zhuihuan-choose",
      skill_name = zhuihuan.name, cancelable = true, no_indicate = true})
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    local choices = {"zhuihuan-damage::" ..tos[1].id, "zhuihuan-discard::" ..tos[1].id}
    if #tos == 1 then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhuihuan.name,
      })
      local target1 = tos[1]
      if choice:startsWith("zhuihuan-damage") then
        handleZhuihuan(room, target1, true, true)
      elseif choice:startsWith("zhuihuan-discard") then
        handleZhuihuan(room, target1, true, false)
      end
    elseif #tos == 2 then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhuihuan.name,
      })
      local target1, target2 = table.unpack(tos)
      if choice:startsWith("zhuihuan-damage") then
        handleZhuihuan(room, target1, true, true)
        handleZhuihuan(room, target2, true, false)
      elseif choice:startsWith("zhuihuan-discard") then
        handleZhuihuan(room, target2, true, true)
        handleZhuihuan(room, target1, true, false)
      end
    end
  end,
})
zhuihuan:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(zhuihuan.name) and target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@ty_heg__zhuihuan_damage") == 1 then
        handleZhuihuan(room, p, false, true)
      end
      if p:getMark("@@ty_heg__zhuihuan_discard") == 1 then
        handleZhuihuan(room, p, false, false)
      end
    end
  end,
})
zhuihuan:addEffect(fk.Death, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(zhuihuan.name, false, true) and player == target
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@ty_heg__zhuihuan_damage") == 1 then
        handleZhuihuan(room, p, false, true)
      end
      if p:getMark("@@ty_heg__zhuihuan_discard") == 1 then
        handleZhuihuan(room, p, false, false)
      end
    end
  end,
})
zhuihuan:addEffect(fk.Damaged, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@ty_heg__zhuihuan_damage") == 1
      and data.from and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    handleZhuihuan(room, target, false, true)
    room:damage{
      from = player,
      to = data.from,
      damage = 1,
      skillName = zhuihuan.name,
    }
  end,
})
zhuihuan:addEffect(fk.Damaged, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@@ty_heg__zhuihuan_discard") == 1
      and data.from and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    handleZhuihuan(room, target, false, false)
    room:askToDiscard(data.from, {
      min_num = 2,
      max_num = 2,
      include_equip = false,
      skill_name = zhuihuan.name,
      cancelable = false,
    })
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__zhuihuan"] = "追还",
  [":ty_heg__zhuihuan"] = "结束阶段，你可选择分配以下效果给至多两名角色直至你下回合开始（各限触发一次）："..
    "1.受到伤害后，伤害来源弃置两张手牌；2.受到伤害后，对伤害来源造成1点伤害。",
  ["#ty_heg__zhuihuan-choose"] = "追还：选择一至两名角色分配对应效果",

  ["@@ty_heg__zhuihuan_discard"] = "追还",
  ["@@ty_heg__zhuihuan_damage"] = "追还",
  ["#ty_heg__zhuihuan-discard"] = "追还",
  ["#ty_heg__zhuihuan-damage"] = "追还",
  ["zhuihuan-damage"] = "对 %dest 分配伤害效果",
  ["zhuihuan-discard"] = "对 %dest 分配弃牌效果",

  ["$ty_heg__zhuihuan1"] = "伤人者，追而还之！",
  ["$ty_heg__zhuihuan2"] = "追而还击，皆为因果。",
}

return zhuihuan
