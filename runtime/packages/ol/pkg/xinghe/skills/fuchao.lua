local fuchao = fk.CreateSkill{
  name = "fuchao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fuchao"] = "覆巢",
  [":fuchao"] = "锁定技，你使用基本牌后，当前回合角色进入连环状态。"..
    "每轮结束时，你与已连环的角色各摸一张牌，然后已连环的角色弃置X张牌（X为已连环的角色数且至少为1）。",

  ["$fuchao1"] = "曹公视我父为仇雠，家门风雨飘摇。",
  ["$fuchao2"] = "你我如卵相累，恐坠顽石之中。",
}

fuchao:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fuchao.name) and data.card.type == Card.TypeBasic then
      local to = player.room:getCurrent()
      return to and not (to.dead or to.chained)
    end
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { player.room.current } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room.current:setChainState(true)
  end,
})

fuchao:addEffect(fk.RoundEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fuchao.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p == player or p.chained
    end)
    room:sortByAction(targets, player)
    event:setCostData(self, { tos = targets })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    ---@type ServerPlayer[]
    local targets = event:getCostData(self).tos

    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards((p == player and p.chained) and 2 or 1, fuchao.name)
      end
    end

    local n = math.max(#table.filter(room.alive_players, function (p)
      return p.chained
    end), 1)

    for _, p in ipairs(targets) do
      if not p.dead and p.chained then
        room:askToDiscard(p, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = fuchao.name,
          cancelable = false,
        })
      end
    end
  end,
})

return fuchao
