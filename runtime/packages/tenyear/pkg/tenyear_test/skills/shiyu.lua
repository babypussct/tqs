
local shiyu = fk.CreateSkill {
  name = "ty__shiyu",
}

Fk:loadTranslationTable{
  ["ty__shiyu"] = "识预",
  [":ty__shiyu"] = "每轮限一次，其他角色的回合开始时，你可以秘密猜测每种类型的牌本回合内是否被该角色使用，"..
  "此回合结束时，你每猜对一种，你获得其一张牌并防止其本轮下次对你造成的伤害；每猜错一种，你与其依次对对方造成1点伤害。"..
  "若你全部猜对，本轮此技能可使用次数+1。",

  ["#ty__shiyu-invoke"] = "识预：你可以猜测 %dest 本回合使用牌的类型，回合结束执行效果",
  ["#ty__shiyu-choice"] = "识预：猜测 %dest 本回合使用牌的类型",
  ["#ty__shiyu-prey"] = "识预：获得 %dest %arg张牌",

  ["$ty__shiyu1"] = "",
  ["$ty__shiyu2"] = "",
}

shiyu:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(shiyu.name) and
      not target.dead and player:usedSkillTimes(shiyu.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shiyu.name,
      prompt = "#ty__shiyu-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = room:askToChoices(player, {
      min_num = 0,
      max_num = 3,
      choices = { "basic", "trick", "equip" },
      skill_name = shiyu.name,
      prompt = "#ty__shiyu-choice::"..target.id,
      cancelable = false,
    })
    room:setPlayerMark(player, "ty__shiyu-turn", choices)
  end,
})

shiyu:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(shiyu.name) and
      player:getMark("ty__shiyu-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark, types = player:getTableMark("ty__shiyu-turn"), {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      if e.data.from == target then
        table.insertIfNeed(types, e.data.card.type)
        if #types == 3 then
          return true
        end
      end
    end, Player.HistoryTurn)
    local right = 0
    if (table.contains(types, Card.TypeBasic) and table.contains(mark, "basic")) or
      (not table.contains(types, Card.TypeBasic) and not table.contains(mark, "basic")) then
      right = right + 1
    end
    if (table.contains(types, Card.TypeTrick) and table.contains(mark, "trick")) or
      (not table.contains(types, Card.TypeTrick) and not table.contains(mark, "trick")) then
      right = right + 1
    end
    if (table.contains(types, Card.TypeEquip) and table.contains(mark, "equip")) or
      (not table.contains(types, Card.TypeEquip) and not table.contains(mark, "equip")) then
      right = right + 1
    end
    if right > 0 then
      room:addTableMarkIfNeed(player, "ty__shiyu_damage-round", target)
      if not target:isNude() then
        local cards = room:askToChooseCards(player, {
          target = target,
          min = right,
          max = right,
          flag = "he",
          skill_name = shiyu.name,
          prompt = "#ty__shiyu-prey::"..target.id..":"..right,
        })
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, shiyu.name, nil, false, player)
        if player.dead then return end
      end
    end
    if right < 3 then
      for _ = 1, 3 - right do
        if not target.dead then
          room:damage {
            from = player,
            to = target,
            damage = 1,
            skillName = shiyu.name,
          }
        end
        if not player.dead then
          room:damage {
            from = target,
            to = player,
            damage = 1,
            skillName = shiyu.name,
          }
        end
      end
    end
    if right == 3 then
      player:setSkillUseHistory(shiyu.name, 0, Player.HistoryRound)
    end
  end,
})

shiyu:addEffect(fk.DetermineDamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.from and
      table.contains(player:getTableMark("ty__shiyu_damage-round"), data.from)
  end,
  on_use = function (self, event, target, player, data)
    player.room:removeTableMark(player, "ty__shiyu_damage-round", data.from)
    data:preventDamage()
  end,
})

return shiyu
