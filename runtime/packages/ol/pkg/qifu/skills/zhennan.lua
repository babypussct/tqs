local zhennan = fk.CreateSkill {
  name = "ol__zhennan",
  tags = { Skill.Limited },
}
Fk:loadTranslationTable {
  ["ol__zhennan"] = "镇南",
  [":ol__zhennan"] = "限定技，准备阶段，你可弃置2张牌，视为使用一张由你指定任意目标的【南蛮入侵】。" ..
      "然后若你对指定目标：造成了伤害，其随机弃置一张牌；未造成伤害，你本回合对其使用牌无次数限制。",

  ["#ol__zhennan-invoke"] = "镇南：你可弃置2张牌，视为使用一张由你指定任意目标的【南蛮入侵】",
  ["#ol__zhennan-choose"] = "镇南：选择任意名角色成为【南蛮入侵】的目标",
  ["@@ol__zhennan-turn"] = "镇南",

  ["$ol__zhennan1"] = "镇守南中，夫君无忧。",
  ["$ol__zhennan2"] = "与君携手，定平蛮夷。",
}

zhennan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(zhennan.name) and
        player:usedSkillTimes(zhennan.name, Player.HistoryGame) == 0 and #player:getCardIds("he") > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = zhennan.name,
      cancelable = true,
      prompt = "#ol__zhennan-invoke",
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = zhennan.name
    room:throwCard(event:getCostData(self).cards, skillName, player, player)
    if player.dead then return end
    local sa = Fk:cloneCard("savage_assault")
    sa.skillName = skillName
    if player:prohibitUse(sa) then return end
    local tos = table.filter(room.alive_players, function(p)
      return p ~= player and not player:isProhibited(p, sa)
    end)
    if #tos == 0 then return end
    if #tos > 1 then
      tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 999,
        targets = tos,
        skill_name = skillName,
        prompt = "#ol__zhennan-choose",
        cancelable = false,
      })
    end
    room:useCard {
      from = player,
      tos = tos,
      card = sa,
      extra_data = { ol__zhennan_user = player }
    }
  end,
})

zhennan:addEffect(fk.Damage, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(zhennan.name) and data.card and not (data.to.dead or data.to:isNude()) then
      local room = player.room
      local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      return (card_event.data.extra_data or {}).ol__zhennan_user == player
    end
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = table.filter(to:getCardIds("h"), function(cid)
      return not to:prohibitDiscard(cid)
    end)
    if #cards == 0 then
      cards = table.filter(to:getCardIds("e"), function(cid)
        return not to:prohibitDiscard(cid)
      end)
    end
    if #cards > 0 then
      room:throwCard(room:tableRandomPick(cards), zhennan.name, to, to)
    end
  end,
})

zhennan:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return (data.extra_data or {}).ol__zhennan_user == player and player:hasSkill(zhennan.name) and
        table.find(data.tos, function(p)
          return not p.dead and (data.damageDealt == nil or data.damageDealt[p] == nil)
        end)
  end,
  on_cost = function(self, event, target, player, data)
    local tos = {}
    for _, p in ipairs(data.tos) do
      if not p.dead and (data.damageDealt == nil or data.damageDealt[p] == nil) then
        table.insertIfNeed(tos, p)
      end
    end
    event:setCostData(self, { tos = tos })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      room:addTableMarkIfNeed(p, "@@ol__zhennan-turn", player)
    end
  end,
})

zhennan:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(to:getTableMark("@@ol__zhennan-turn"), player)
  end,
})
zhennan:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    local to = table.find(data.tos, function(to)
      return #to:getTableMark("@@ol__zhennan-turn") > 0
    end)
    return target == player and player:hasSkill(zhennan.name) and
        to and table.contains(to:getTableMark("@@ol__zhennan-turn"), player)
        and not data.extraUse
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})


return zhennan
