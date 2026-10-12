local yaohu = fk.CreateSkill {
  name = "yaohu",
}

Fk:loadTranslationTable{
  ["yaohu"] = "邀虎",
  [":yaohu"] = "每轮限一次，你的回合开始时，你须选择场上一个势力。此势力的其他角色出牌阶段开始时，其获得你的一张“生”，然后其须选择一项："..
  "1.对你指定的一名其攻击范围内的其他角色使用一张不计入次数的【杀】；2.本阶段其使用伤害类牌指定你为目标时，须交给你两张牌，否则取消之。",

  ["#yaohu-choice"] = "邀虎：选择你要“邀虎”的势力",
  ["@yaohu"] = "邀虎",
  ["@@yaohu-phase"] = "邀虎",
  ["#yaohu-choose"] = "邀虎：选择令 %dest 使用【杀】的目标",
  ["#yaohu-slash"] = "邀虎：你需对 %dest 使用一张【杀】，否则本阶段使用伤害牌指定 %src 为目标时需交给其牌",
  ["#yaohu-give"] = "邀虎：你需交给 %src 两张牌，否则其取消此%arg",

  ["$yaohu1"] = "益州疲敝，还望贤兄相助。",
  ["$yaohu2"] = "内讨米贼，外拒强曹，璋无宗兄万万不可啊。",
}

yaohu:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yaohu.name) and
      player:usedEffectTimes(yaohu.name, Player.HistoryRound) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local choice = room:askToChoice(player, {
      choices = kingdoms,
      skill_name = yaohu.name,
      prompt = "#yaohu-choice",
    })
    room:setPlayerMark(player, "@yaohu", choice)
  end,
})
yaohu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yaohu.name) and target ~= player and target.phase == Player.Play and not target.dead and
      player:getMark("@yaohu") == target.kingdom and #player:getPile("liuzhang_sheng") > 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = target})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(target, {
      target = player,
      flag = {
        card_data = {{yaohu.name, player:getPile("liuzhang_sheng")}}
      },
      skill_name = yaohu.name,
    })
    room:obtainCard(target, id, true, fk.ReasonPrey, target, yaohu.name)
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return target:inMyAttackRange(p)
    end)
    if #targets == 0 then
      room:addTableMark(target, "@@yaohu-phase", player.id)
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = yaohu.name,
        prompt = "#yaohu-choose::"..target.id,
        cancelable = false,
        no_indicate = true,
      })[1]
      room:doIndicate(target, {to})
      local use = room:askToUseCard(target, {
        skill_name = yaohu.name,
        pattern = "slash",
        prompt = "#yaohu-slash:"..player.id..":"..to.id,
        extra_data = {
          exclusive_targets = {to.id},
          bypass_times = true,
        }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      else
        room:addTableMark(target, "@@yaohu-phase", player.id)
      end
    end
  end,
})
yaohu:addEffect(fk.TargetSpecifying, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.to == player and table.contains(target:getTableMark("@@yaohu-phase"), player.id) and
      data.card.is_damage_card and not data.cancelled
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if #target:getCardIds("he") < 2 then
      data:cancelCurrentTarget()
    else
      local cards = room:askToCards(target, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = yaohu.name,
        prompt = "#yaohu-give:"..player.id.."::"..data.card:toLogString(),
        cancelable = true,
      })
      if #cards == 2 then
        room:obtainCard(player, cards, false, fk.ReasonGive, target, yaohu.name)
      else
        data:cancelCurrentTarget()
      end
    end
  end,
})

return yaohu
