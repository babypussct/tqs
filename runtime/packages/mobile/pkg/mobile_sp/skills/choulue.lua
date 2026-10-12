local choulue = fk.CreateSkill {
  name = "choulue",
}

Fk:loadTranslationTable{
  ["choulue"] = "筹略",
  [":choulue"] = "出牌阶段开始时，你可以令一名其他角色选择是否交给你一张牌，若其执行，你可视为使用上一张除延时锦囊牌以外对你造成伤害的牌。",

  ["#choulue-choose"] = "筹略：令一名其他角色选择是否交给你一张牌",
  ["#choulue-ask"] = "筹略：你可以交给 %dest 一张牌，若交给，其可以转化牌",
  ["@choulue"] = "筹略",

  ["$choulue1"] = "依此计行，可安军心。",
  ["$choulue2"] = "破袁之策，吾已有计。",
}

choulue:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(choulue.name) and target == player and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#choulue-choose",
          skill_name = choulue.name,
        }
      )
      if #tos > 0 then
        event:setCostData(self, { tos = tos })
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = choulue.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToCards(
      to,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        prompt = "#choulue-ask::" .. player.id,
      }
    )
    if #cards > 0 then
      room:obtainCard(player, cards[1], false, fk.ReasonGive, to, skillName)
      local name = player:getMark("@choulue")
      if name ~= 0 then
        room:askToUseVirtualCard(player, { name = name, skill_name = skillName })
      end
    end
  end,
})

choulue:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(choulue.name, true) and
      target == player and
      data.card and
      data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@choulue", data.card.trueName)
  end,
})

return choulue
