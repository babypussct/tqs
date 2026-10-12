local wushuang = fk.CreateSkill {
  name = "os_mou__wushuang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os_mou__wushuang"] = "无双",
  [":os_mou__wushuang"] = "锁定技，当你使用【杀】指定目标后，其使用【闪】抵消此【杀】的方式改为需连续使用两张【闪】；" ..
  "当你使用【决斗】指定目标后，或当你成为【决斗】的目标后，你令其打出【杀】响应此【决斗】的方式改为需连续打出两张【杀】。" ..
  "每回合限两次，当此【杀】或【决斗】对其造成伤害时，若其未使用或打出【杀】或【闪】响应过此牌，则此伤害+1。",

  ["$os_mou__wushuang1"] = "小儿何往？与某再战一场！",
  ["$os_mou__wushuang2"] = "无双之力，岂是尔等可挡？",
  ["$os_mou__wushuang3"] = "哈哈哈哈，我这画戟滋味如何？",
  ["$os_mou__wushuang4"] = "哼，教汝摧身裂胆，魂飞魄荡。",
  ["$os_mou__wushuang5"] = "黄口竖子，何敢挑衅于我。",
  ["$os_mou__wushuang6"] = "这熟悉的力量，本该由我掌控。",
}

wushuang:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  audio_index = { 3, 4 },
  times = function(self, player)
    return 2 - player:usedEffectTimes(self.name)
  end,
  can_trigger = function(self, event, target, player, data)
    if
      not (
        target == player and
        player:hasSkill(wushuang.name) and
        data.card and
        table.contains({ "slash", "duel" }, data.card.trueName) and
        player:usedEffectTimes(self.name) < 2
      )
    then
      return false
    end

    local effectEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if effectEvent then
      local effectData = effectEvent.data
      if not table.contains((effectData.extra_data or {}).wushuangTargets or {}, data.to) then
        return false
      end

      if effectData.card.trueName == "slash" then
        return not table.find(effectData.cardsResponded or {},
          function(card) return card.trueName == "jink"
        end)
      elseif effectData.card.trueName == "duel" then
        return #player.room.logic:getEventsByRule(GameEvent.RespondCard, 1, function(e)
          local responseData = e.data
          return
            responseData.card.trueName == "slash" and
            responseData.responseToEvent == effectData and
            responseData.from == data.to
        end, nil, Player.HistoryTurn) == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

---@type TrigSkelSpec<AimFunc>
local spec = {
  on_use = function(self, event, target, player, data)
    local to = (event == fk.TargetConfirmed and data.card.trueName == "duel") and data.from or data.to
    player.room:notifySkillInvoked(player, wushuang.name, "offensive")
    if data.card.trueName == "duel" and to:hasSkill("wushuang") then
      player:broadcastSkillInvoke(wushuang.name, math.random(5, 6))
    else
      player:broadcastSkillInvoke(wushuang.name, math.random(1, 2))
    end

    data:setResponseTimes(2, to)
    data.extra_data = data.extra_data or {}
    data.extra_data.wushuangTargets = data.extra_data.wushuangTargets or {}
    table.insertIfNeed(data.extra_data.wushuangTargets, to)
  end,
}

wushuang:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(wushuang.name) and
      table.contains({ "slash", "duel" }, data.card.trueName)
  end,
  on_use = spec.on_use,
})

wushuang:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wushuang.name) and data.card.trueName == "duel"
  end,
  on_use = spec.on_use,
})

return wushuang
