local jinglei = fk.CreateSkill{
  name = "jinglei",
}

Fk:loadTranslationTable{
  ["jinglei"] = "惊雷",
  [":jinglei"] = "每回合限一次，一名角色使用【酒】结算后，若没有处于濒死状态的角色，你可以受到1点无来源的雷电伤害，令一名拥有〖煮酒〗的角色"..
  "将手牌调整至体力上限（至多摸至五张），若不为你，其将以此法弃置的牌交给你。",

  ["#jinglei-choose"] = "惊雷：你可以令一名有“煮酒”的角色将手牌调整至体力上限（至多摸至五）",

  ["$jinglei1"] = "备得仕于朝，天下英雄实有未知。",
  ["$jinglei2"] = "闻惊雷而颤，备肉眼安识英雄？",
}

jinglei:addEffect(fk.CardUseFinished, {
  times = function (_, player)
    return 1 - player:usedSkillTimes(jinglei.name, Player.HistoryTurn)
  end,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jinglei.name) and data.card.trueName == "analeptic" and
      player:usedSkillTimes(jinglei.name, Player.HistoryTurn) == 0 and
      table.find(player.room.alive_players, function(p)
        return p:hasSkill("zhujiu", true)
      end) and
      table.every(player.room.alive_players, function(p)
        return not p.dying
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = jinglei.name})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage{
      to = player,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = jinglei.name,
    }
    if player.dead then return end
    local targets = table.filter(room.alive_players, function(p)
      return p:hasSkill("zhujiu", true)
    end)
    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = jinglei.name,
      prompt = "#jinglei-choose",
      cancelable = false,
    })

    local to = tos[1]
    if to.dead then return end
    local target_num = math.min(to.maxHp, 5)
    local cur_num = to:getHandcardNum()
    if cur_num > target_num then
      local discard_num = cur_num - target_num
      local cards = room:askToDiscard(to, {
        min_num = discard_num,
        max_num = discard_num,
        include_equip = false,
        skill_name = jinglei.name,
        cancelable = false,
      })
      if to ~= player and not player.dead and #cards > 0 then
        cards = table.filter(cards, function(id)
          return table.contains(room.discard_pile, id)
        end)
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, jinglei.name, nil, true, player)
        end
      end
    elseif cur_num < target_num then
      to:drawCards(target_num - cur_num, jinglei.name)
    end
  end,
})

return jinglei