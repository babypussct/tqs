local sidi = fk.CreateSkill {
  name = "m_ex__sidi",
}

Fk:loadTranslationTable{
  ["m_ex__sidi"] = "司敌",
  [":m_ex__sidi"] = "当你使用除延时锦囊以外的牌结算结束后，可以选择一名还未指定“司敌”目标的其他角色，并为其指定一名“司敌”目标角色（均不可见）。"..
    "其使用的第一张除延时锦囊以外的牌仅指定“司敌”目标为唯一角色时（否则清除你为其指定的“司敌”目标角色），"..
    "你根据以下情况执行效果：若目标为你，你摸一张牌；若目标不为你，你选择："..
    "1.取消之，然后若此时场上没有任何角色处于濒死状态，你对其造成1点伤害；2.你摸两张牌。然后清除你为其指定的“司敌”目标角色。",

  ["#m_ex__sidi-choose"] = "你可发动司敌，选择1名角色，为其指定司敌目标",
  ["#m_ex__sidi-choose2"] = "司敌：为%dest指定司敌目标，若正确，可发动响应效果",
  ["#m_ex__sidi-choice"] = "司敌：选择取消%dest使用的%arg，或摸两张牌",
  ["m_ex__sidi_negate"] = "取消此牌",
  ["m_ex__sidi_negate_and_damage"] = "取消此牌并对使用者造成伤害",
  ["@[m_ex__sidi]"] = "司敌",

  ["$m_ex__sidi1"] = "司敌之动，先发而制。",
  ["$m_ex__sidi2"] = "料敌之行，伏兵灭之。",
}

Fk:addQmlMark{
  name = "m_ex__sidi",
  qml_path = "",
  how_to_show = function(name, value, p)
    if type(value) == "table" then
      for _, sidi_pair in ipairs(value) do
        if sidi_pair[1] == Self.id then
          local ret = Fk:translate(Fk:currentRoom():getPlayerById(sidi_pair[2]).general)
          return ret
        end
      end
    end
    return " "
  end,
}

sidi:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sidi.name) and data.card.sub_type ~= Card.SubtypeDelayedTrick and
    table.find(player.room.alive_players, function(p)
      return p ~= player and table.every(p:getTableMark("@[m_ex__sidi]"), function(value)
        return value[1] ~= player.id
      end)
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = table.filter(room.alive_players, function(p)
        return p ~= player and table.every(p:getTableMark("@[m_ex__sidi]"), function(value)
          return value[1] ~= player.id
        end)
      end),
      skill_name = sidi.name,
      prompt = "#m_ex__sidi-choose",
      cancelable = true,
      no_indicate = true
    })
    if #tos > 0 then
      local tos2 = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = sidi.name,
        prompt = "#m_ex__sidi-choose2::" .. tos[1].id,
        cancelable = true,
        no_indicate = true
      })
      if #tos2 > 0 then
        event:setCostData(self, {tos = tos, choice = tos2[1].id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local dat = event:getCostData(self)
    player.room:addTableMark(dat.tos[1], "@[m_ex__sidi]", {player.id, dat.choice})
  end,
})

---@param player ServerPlayer
---@param pid integer
local removeSidiMark = function(player, pid)
  local mark = player:getTableMark("@[m_ex__sidi]")
  local new_mark = table.filter(mark, function (value)
    return value[1] ~= pid
  end)
  if #new_mark ~= #mark then
    player.room:setPlayerMark(player, "@[m_ex__sidi]", #new_mark > 0 and new_mark or 0)
  end
end

sidi:addEffect(fk.TargetSpecifying, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not data.from.dead and data.card.sub_type ~= Card.SubtypeDelayedTrick and
    not data.cancelled and data:isOnlyTarget(data.to) and player:hasSkill(sidi.name) and
    table.find(data.from:getTableMark("@[m_ex__sidi]"), function (value)
      return value[1] == player.id and value[2] == data.to.id
    end)
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, {tos = {data.from}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.to == player then
      room:drawCards(player, 1, sidi.name)
    else
      local choices = {"m_ex__sidi_negate", "draw2"}
      if not data.from.dead and table.every(room.alive_players, function(p) return not p.dying end) then
        choices[1] = "m_ex__sidi_negate_and_damage"
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = sidi.name,
        prompt = "#m_ex__sidi-choice::"..data.from.id..":"..data.card:toLogString(),
      })
      if choice == "draw2" then
        room:drawCards(player, 2, sidi.name)
      else
        data:cancelAllTarget()
        if not data.from.dead and table.every(room.alive_players, function(p) return not p.dying end) then
          room:damage{
            from = player,
            to = data.from,
            damage = 1,
            skillName = sidi.name,
          }
        end
        if not data.from.dead then
          removeSidiMark(data.from, player.id)
        end
        return true
      end
    end
    if not data.from.dead then
      removeSidiMark(data.from, player.id)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player == data.from and player:getMark("@[m_ex__sidi]") ~= 0 and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = data.from:getTableMark("@[m_ex__sidi]")
    if data:isOnlyTarget(data.to) then
      local new_mark = table.filter(mark, function (value)
        return value[2] == data.to.id
      end)
      if #new_mark ~= #mark then
        player.room:setPlayerMark(player, "@[m_ex__sidi]", #new_mark > 0 and new_mark or 0)
      end
    else
      player.room:setPlayerMark(player, "@[m_ex__sidi]", 0)
    end
  end,
})

sidi:addLoseEffect(function(self, player)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    removeSidiMark(p, player.id)
  end
end)

return sidi
