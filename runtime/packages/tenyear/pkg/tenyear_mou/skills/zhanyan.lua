local zhanyan = fk.CreateSkill {
  name = "zhanyan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zhanyan"] = "绽炎",
  [":zhanyan"] = "限定技，出牌阶段，你可以选择任意名横置的其他角色并回复等量体力，所选角色同时展示一张手牌，" ..
  "然后你可弃置至少一张其中含有的花色的牌并对展示了对应花色的角色各造成1点火焰伤害，若所选角色均因此受到了伤害则你重复此流程。" ..
  "此技能结算期间每当你失去牌后你摸等量张牌。",

  ["#zhanyan"] = "绽炎：选择任意名横置的角色，你回复体力并执行效果",
  ["#zhanyan-display"] = "绽炎：请选择一张手牌展示",
  ["#zhanyan-discard"] = "绽炎：弃置至少一张其中花色的牌，对对应花色的角色造成火焰伤害",

  ["$zhanyan1"] = "东风若知趣，应携离火来！",
  ["$zhanyan2"] = "今日便让这七百里烽火，照亮尔等愚目！",
}

zhanyan:addEffect("active", {
  prompt = "#zhanyan",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 9,
  can_use = function(self, player)
    return player:usedSkillTimes(zhanyan.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return player ~= to_select and to_select.chained
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = zhanyan.name
    local player = effect.from
    local targets = table.simpleClone(effect.tos)
    room:recover{
      who = player,
      num = #targets,
      recoverBy = player,
      skillName = zhanyan.name,
    }
    if player.dead then return end
    local currentEvent = room.logic:getCurrentEvent()
    currentEvent:addCleaner(function()
      room:setPlayerMark(player, "zhanyan_effect", 0)
    end)

    local victimList
    local endId = nil
    repeat
      endId = room.logic.current_event_id
      room:setPlayerMark(player, "zhanyan_effect", 1)
      victimList = {}
      local realTargets = table.filter(targets, function(p) return p:isAlive() and not p:isKongcheng() end)
      if #realTargets == 0 then
        return false
      end

      room:sortByAction(realTargets)
      local results = room:askToJointCards(
        player,
        {
          players = realTargets,
          min_num = 1,
          max_num = 1,
          skill_name = skillName,
          prompt = "#zhanyan-display",
          cancelable = false,
        }
      )

      local suitsDisplayed = {}
      local suitsMapper = {}
      for p, ids in pairs(results) do
        local suitStr = Fk:getCardById(ids[1]):getSuitString()
        table.insertIfNeed(suitsDisplayed, suitStr)
        suitsMapper[p] = suitStr
        p:showCards(ids)
      end

      if not player:isAlive() then
        return false
      end

      local toThrow = room:askToDiscard(
        player,
        {
          min_num = 1,
          max_num = player:getHandcardNum(),
          pattern = ".|.|" .. table.concat(suitsDisplayed, ","),
          include_equip = true,
          skill_name = skillName,
          prompt = "#zhanyan-discard",
        }
      )

      if #toThrow == 0 then
        return false
      end

      local suitsDiscarded = {}
      for _, id in ipairs(toThrow) do
        table.insertIfNeed(suitsDiscarded, Fk:getCardById(id):getSuitString())
      end

      for _, p in ipairs(realTargets) do
        if table.contains(suitsDiscarded, suitsMapper[p]) and p:isAlive() then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = skillName,
          }
        end
      end

      room.logic:getActualDamageEvents(1, function(e)

        local damage = e.data
        if damage.from == player and damage.skillName == skillName and table.contains(targets, damage.to) then
          table.insertIfNeed(victimList, damage.to)
        end

        return false
      end, nil, endId)
    until #victimList ~= #targets or not player:isAlive()
  end,
})

zhanyan:addEffect(fk.AfterCardsMove, {
  is_delay_effect = true,
  mute = true,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      player:getMark("zhanyan_effect") > 0 and
      player:getMark("zhanyan_effect") < 21 and
      table.find(data, function(move)
        return
          move.from == player and
          not not table.find(move.moveInfo, function(info)
            return
              table.contains({ Card.PlayerHand, Card.PlayerEquip }, info.fromArea) and
              (
                move.to ~= move.from or
                not table.contains({ Card.PlayerHand, Card.PlayerEquip }, move.toArea)
              )
          end)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "zhanyan_effect")

    local drawNum = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if
            table.contains({ Card.PlayerHand, Card.PlayerEquip }, info.fromArea) and
            (
              move.to ~= move.from or
              not table.contains({ Card.PlayerHand, Card.PlayerEquip }, move.toArea)
            )
          then
            drawNum = drawNum + 1
          end
        end
      end
    end

    player:drawCards(drawNum, zhanyan.name)
  end,
})

return zhanyan
