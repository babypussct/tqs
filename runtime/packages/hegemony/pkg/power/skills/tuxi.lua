local tuxi = fk.CreateSkill {
  name = "jianan__ex__tuxi",
}

Fk:loadTranslationTable {
  ["jianan__ex__tuxi"] = "突袭",
  [":jianan__ex__tuxi"] = "摸牌阶段，你可以少摸任意张牌并获得等量其他角色各一张手牌。",
  ["#jianan__ex__tuxi-choose"] = "突袭：你可以少摸至多%arg张牌，获得等量其他角色各一张手牌",

  ["$jianan__ex__tuxi1"] = "以百破万，让孤再看一次！",
  ["$jianan__ex__tuxi2"] = "望将军身影，可治孤之头风病。",
}

tuxi:addEffect(fk.DrawNCards, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuxi.name) and data.n > 0 and
        table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:isKongcheng() end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = data.n,
      prompt = "#jianan__ex__tuxi-choose:::" .. data.n,
      skill_name = tuxi.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    room:sortByAction(tos)
    for _, id in ipairs(tos) do
      local to = id
      if not (to.dead or to:isKongcheng()) then
        local c = room:askToChooseCard(player, {
          target = to,
          flag = "h",
          skill_name = tuxi.name,
        })
        room:obtainCard(player, c, false, fk.ReasonPrey)
        if player.dead then break end
      end
    end
    data.n = data.n - #tos
  end,
})

return tuxi
