local saying = fk.CreateSkill{
  name = "ol__saying",
}

Fk:loadTranslationTable{
  ["ol__saying"] = "飒影",
  [":ol__saying"] = "出牌阶段开始时，你可以获得一名其他角色区域内的一张牌，然后若你在其攻击范围内，其可以对你使用一张【杀】；"..
  "若你不在其攻击范围内，本轮你与其视为在对方的攻击范围内。",

  ["#ol__saying-choose"] = "飒影：获得一名角色区域内一张牌，根据你是否在其攻击范围内执行效果",
  ["#ol__saying-use"] = "飒影：你可以对 %src 使用一张【杀】",

  ["$ol__saying1"] = "残影过处，唯余霜刃映血！",
  ["$ol__saying2"] = "箭雨未至影先行，破阵犹似过惊鸿。",
}

saying:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(saying.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return p ~= player and not p:isAllNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and not p:isAllNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = saying.name,
      prompt = "#ol__saying-choose",
      cancelable = true,
      no_indicate = true
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "hej",
      skill_name = saying.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, saying.name, nil, false, player)
    if player.dead or to.dead then return end
    if to:inMyAttackRange(player) then
      local use = room:askToUseCard(to, {
        skill_name = saying.name,
        pattern = "slash",
        prompt = "#ol__saying-use:"..player.id,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          exclusive_targets = { player.id },
        }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    else
      room:addTableMarkIfNeed(player, "ol__saying-round", to)
      room:addTableMarkIfNeed(to, "ol__saying-round", player)
    end
  end,
})

saying:addEffect("atkrange", {
  within_func = function(self, from, to)
    return table.contains(from:getTableMark("ol__saying-round"), to)
  end,
})

return saying
