local dongcha = fk.CreateSkill {
  name = "vd_dongcha",
  mode_skill = true,
}

Fk:loadTranslationTable{
  ["vd_dongcha"] = "洞察",
  [":vd_dongcha"] = "游戏开始时，随机一名反贼的身份对你可见。准备阶段，你可以弃置场上的一张牌。",

  ["#vd_dongcha-choose"] = "洞察：你可以弃置一名角色场上一张牌",
  ["#VDDongcha"] = "明忠 %from 发动了〖洞察〗，一名反贼的身份已被其知晓",
}

dongcha:addEffect(fk.GameStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dongcha.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p.role == "rebel"
    end)
    if #targets > 0 then
      room:addTableMark(player, "vd_dongcha", room:tableRandomPick(targets).id)
    end
    room:sendLog{
      type = "#VDDongcha",
      from = player.id,
      toast = true,
    }
  end,
})

dongcha:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(player.room.alive_players, function(p)
        return #p:getCardIds("ej") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return #p:getCardIds("ej") > 0
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = dongcha.name,
      prompt = "#vd_dongcha-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "ej",
      skill_name = dongcha.name,
    })
    room:throwCard(card, dongcha.name, to, player)
  end,
})

dongcha:addEffect("visibility", {
  role_visible = function (self, player, target)
    if table.contains(player:getTableMark("vd_dongcha"), target.id) then
      return true
    end
  end,
})

return dongcha
