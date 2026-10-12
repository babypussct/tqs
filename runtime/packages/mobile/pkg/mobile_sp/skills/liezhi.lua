local liezhi = fk.CreateSkill{
  name = "liezhi",
}

Fk:loadTranslationTable{
  ["liezhi"] = "烈直",
  [":liezhi"] = "准备阶段，你可以依次弃置至多两名其他角色区域内的各一张牌；当你受到伤害后，〖烈直〗失效直到你的下个结束阶段。",

  ["#liezhi-choose"] = "烈直：弃置至多两名其他角色区域内一张牌",

  ["$liezhi1"] = "只恨箭支太少，不能射杀汝等！",
  ["$liezhi2"] = "身陨事小，秉节事大。",
}

liezhi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liezhi.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isAllNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isAllNude()
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 2,
      targets = targets,
      skill_name = liezhi.name,
      prompt = "#liezhi-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(event:getCostData(self).tos) do
      if player.dead then break end
      if not to:isAllNude() and not to.dead then
        local id = room:askToChooseCard(player, {
          target = to,
          flag = "hej",
          skill_name = liezhi.name,
        })
        room:throwCard(id, liezhi.name, to, player)
      end
    end
  end,
})
liezhi:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(liezhi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:invalidateSkill(player, liezhi.name)
    player.room:setPlayerMark(player, "liezhi_failed", 1)
  end,
})
liezhi:addEffect(fk.EventPhaseStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(liezhi.name, true) and player.phase == Player.Finish and
      player:getMark("liezhi_failed") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:validateSkill(player, liezhi.name)
    player.room:setPlayerMark(player, "liezhi_failed", 0)
  end,
})

return liezhi
