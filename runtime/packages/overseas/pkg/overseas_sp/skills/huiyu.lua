local huiyu = fk.CreateSkill{
  name = "os__huiyu",
}

Fk:loadTranslationTable{
  ["os__huiyu"] = "毁誉",
  [":os__huiyu"] = "准备阶段，你可以选择两名角色，令第一名角色代替成为第二名角色下个出牌阶段造成的伤害的来源。",

  ["#os__huiyu-choose"] = "你可发动 毁誉，选择两名角色，令第一名角色代替成为第二名角色下个出牌阶段造成的伤害的来源",

  ["os__huiyu_substitute"] = "伤害来源",
  ["os__huiyu_substituendum"] = "被代替",

  ["@[chara]os__huiyu_substituendum"] = "毁誉 被代替",
  ["@[chara]os__huiyu_substituendum-phase"] = "毁誉 被代替",

  ["$os__huiyu1"] = "长子失德，当刑以正视听！",
  ["$os__huiyu2"] = "少子有成，当裱而沐春风！",
}

huiyu:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(huiyu.name) and player.phase == Player.Start and #player.room.alive_players > 1
  end,
  on_cost = function (self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      targets = player.room.alive_players,
      min_num = 2,
      max_num = 2,
      prompt = "#os__huiyu-choose",
      skill_name = huiyu.name,
      cancelable = true,
      target_tip_name = huiyu.name,
    })
    if #tos == 2 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos ---@type ServerPlayer[]
    local substitute = tos[1]
    local substituendum = tos[2]
    room:setPlayerMark(substituendum, "@[chara]os__huiyu_substituendum", substitute.id)
    room:addTableMark(player, "_os__huiyu_substitutes", substitute.id)
  end
})

huiyu:addEffect(fk.EventPhaseStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      player:getMark("@[chara]os__huiyu_substituendum") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local substitute = player:getMark("@[chara]os__huiyu_substituendum")
    room:setPlayerMark(target, "@[chara]os__huiyu_substituendum-phase", substitute)
    room:setPlayerMark(target, "@[chara]os__huiyu_substituendum", 0)
  end,
})

huiyu:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@[chara]os__huiyu_substituendum-phase") ~= 0 and
      player.room:getPlayerById(player:getMark("@[chara]os__huiyu_substituendum-phase")):isAlive()
  end,
  on_use = function (self, event, target, player, data)
    data.from = player.room:getPlayerById(player:getMark("@[chara]os__huiyu_substituendum-phase"))
  end
})

Fk:addTargetTip{
  name = "os__huiyu",
  target_tip = function(self, player, to_select, selected)
    if #selected == 0 or (#selected > 0 and selected[1] == to_select) then
      return "os__huiyu_substitute"
    else
      return "os__huiyu_substituendum"
    end
  end,
}

return huiyu
