local tingwei = fk.CreateSkill{
  name = "os__tingwei",
}

Fk:loadTranslationTable{
  ["os__tingwei"] = "霆威",
  [":os__tingwei"] = "你使用【杀】指定目标后，可以获得4个“霆”标记并选择一名目标角色，其选择任意项（每选择一项，你失去1个“霆”标记）：<br>"..
  "1.非锁定技失效至其下个回合结束；<br>"..
  "2.交给你一张装备牌；<br>"..
  "3.此牌对其造成伤害+1：<br>"..
  "4.随机弃两张牌。<br>"..
  "若其均不选择，其进入连环状态。",

  ["@machao_thunder"] = "霆",
  ["#os__tingwei-choose"] = "霆威：获得4个“霆”标记，令一名目标角色选择执行任意项",
  ["#os__tingwei-invoke"] = "霆威：获得4个“霆”标记，令 %dest 选择执行任意项",
  ["#os__tingwei-choice"] = "霆威：执行任意项以令 %src 失去等量“霆”标记，不执行则进入连环状态",
  ["os__tingwei_1"] = "非锁定技失效至你下个回合结束",
  ["os__tingwei_2"] = "交给其一张装备牌",
  ["os__tingwei_3"] = "此牌对你造成伤害+1",
  ["os__tingwei_4"] = "随机弃两张牌",
  ["@@tingwei_invalidity"] = "非锁定技失效",
  ["#os__tingwei-give"] = "霆威：交给 %src 一张装备牌",

  ["$os__tingwei1"] = "",
  ["$os__tingwei2"] = "",
  ["$os__tingwei3"] = "",
  ["$os__tingwei4"] = "",
}

tingwei:addEffect(fk.TargetSpecified, {
  audio_index = { 1, 2 },
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tingwei.name) and
      data.firstTarget and data.card.trueName == "slash" and
      table.find(data.use.tos, function (p)
        return not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.use.tos, function (p)
      return not p.dead
    end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = tingwei.name,
        prompt = "#os__tingwei-invoke::" .. targets[1].id,
      }) then
        event:setCostData(self, { tos = targets })
        return true
      end
    else
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__tingwei-choose",
        skill_name = tingwei.name,
        cancelable = true,
      })
      if #targets > 0 then
        event:setCostData(self, { tos = targets })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addPlayerMark(player, "@machao_thunder", 4)
    local equip = table.find(to:getCardIds("he"), function (id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    local all_choices = { "os__tingwei_1", "os__tingwei_2", "os__tingwei_3", "os__tingwei_4" }
    local choices = table.simpleClone(all_choices)
    if not equip then table.remove(choices, 2) end
    if to:isNude() then table.remove(choices) end
    choices = room:askToChoices(to, {
      choices = choices,
      min_num = 0,
      max_num = #choices,
      all_choices = all_choices,
      skill_name = tingwei.name,
      prompt = "#os__tingwei-choice:"..player.id,
      cancelable = true,
    })
    if table.contains(choices, "os__tingwei_1") then
      room:addPlayerMark(to, "@@tingwei_invalidity", 1)
      room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity, 1)
    end
    if table.contains(choices, "os__tingwei_2") then
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = tingwei.name,
        pattern = ".|.|.|.|.|equip",
        prompt = "#os__tingwei-give:" .. player.id,
        cancelable = false,
      })
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, tingwei.name, nil, false, to)
      end
    end
    if table.contains(choices, "os__tingwei_3") then
      data.extra_data = data.extra_data or {}
      data.extra_data.os__tingwei = data.extra_data.os__tingwei or {}
      table.insert(data.extra_data.os__tingwei, to.id)
    end
    if table.contains(choices, "os__tingwei_4") then
      local cards = table.filter(to:getCardIds("he"), function (id)
        return not to:prohibitDiscard(id)
      end)
      if #cards > 0 then
        room:throwCard(room:tableRandomPick(cards, 2), tingwei.name, to, to)
      else
        table.removeOne(choices, "os__tingwei_4")
      end
    end
    if #choices == 0 and not to.chained then
      player:broadcastSkillInvoke(tingwei.name, math.random(3, 4))
      to:setChainState(true)
    end
    if #choices > 0 then
      room:removePlayerMark(player, "@machao_thunder", #choices)
    end
  end,
})

tingwei:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not use_event then return false end
    local use = use_event.data
    return use.extra_data and use.extra_data.os__tingwei and table.contains(use.extra_data.os__tingwei, player.id)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

tingwei:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@tingwei_invalidity") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, MarkEnum.UncompulsoryInvalidity, player:getMark("@@tingwei_invalidity"))
    room:setPlayerMark(player, "@@tingwei_invalidity", 0)
  end,
})

return tingwei
