local weifeng = fk.CreateSkill {
  name = "weifeng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["weifeng"] = "威风",
  [":weifeng"] = "锁定技，你于出牌阶段第一次使用【杀】或伤害类锦囊牌结算后，你选择其中一名没有“惧”的其他目标角色，令其获得此牌名的“惧”标记。"..
  "有“惧”的角色受到伤害时，移除“惧”并执行效果：若造成伤害的牌名与“惧”相同，则此伤害+1；若不同，你获得其一张牌。准备阶段或你死亡时，移除所有“惧”。",

  ["#weifeng-choose"] = "威风：令一名角色获得“惧”标记",
  ["@weifeng"] = "惧",
  ["#weifeng-prey"] = "威风：获得 %dest 一张牌",

  ["$weifeng1"] = "广散惧义，尽泄敌之斗志。",
  ["$weifeng2"] = "若尔等惧我，自当卷甲以降。",
}

weifeng:addLoseEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    room:setPlayerMark(p, "@weifeng", 0)
  end
end)
weifeng:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(weifeng.name) and player.phase == Player.Play and data.card.is_damage_card then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and use.card.is_damage_card
      end, Player.HistoryPhase)
      if events[1].id == player.room.logic:getCurrentEvent().id then
        return table.find(data.tos, function(p)
          return p ~= player and not p.dead and p:getMark(weifeng.name) == 0
        end) and player:usedSkillTimes(weifeng.name, Player.HistoryPhase) == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function(p)
      return p ~= player and not p.dead and p:getMark(weifeng.name) == 0
    end)
    if #targets == 1 then
      room:setPlayerMark(targets[1], "@weifeng", data.card.trueName)
    elseif #targets > 1 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = weifeng.name,
        prompt = "#weifeng-choose",
        cancelable = false,
      })[1]
      room:setPlayerMark(to, "@weifeng", data.card.trueName)
    end
  end,
})
weifeng:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(weifeng.name) and target:getMark("@weifeng") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    if data.card and data.card.trueName == target:getMark("@weifeng") then
      data:changeDamage(1)
    elseif not target:isNude() then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = "weifeng",
        prompt = "#weifeng-prey::"..player.id
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, weifeng.name)
    end
    room:setPlayerMark(target, "@weifeng", 0)
  end,
})
weifeng:addEffect(fk.EventPhaseStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(weifeng.name, true) and player.phase == Player.Start
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@weifeng", 0)
    end
  end,
})

return weifeng
