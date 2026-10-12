local osChungang = fk.CreateSkill {
  name = "os__chungang",
}

Fk:loadTranslationTable{
  ["os__chungang"] = "纯刚",
  [":os__chungang"] = "游戏开始时或出牌阶段限一次，你可以令至多两名角色各摸一张牌。" ..
      "其他角色使用以此法获得的牌时，其须弃置一张牌。",

  ["#os__chungang-active"] = "你可以发动〖纯刚〗，令至多两名角色各摸一张牌",
  ["@@os__chungang-inhand"] = "纯刚",
  ["#os__chungang-discard"] = "受到 %src〖纯刚〗的影响，请弃置一张牌",

  ["$os__chungang1"] = "陛下若此，天下何以观之！",
  ["$os__chungang2"] = "偏听谄谀之言，此为万民所仰之君乎？"
}

osChungang:addEffect("active", {
  prompt = "#os__chungang-active",
  anim_type = "support",
  max_phase_use_time = 1,
  max_target_num = 2,
  min_target_num = 1,
  target_filter = function (self, _, _, selected)
    return #selected < 2
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function (self, room, effect)
    local targets = effect.tos
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if p:isAlive() then
        p:drawCards(1, osChungang.name, nil, "@@os__chungang-inhand")
      end
    end
  end,
})

osChungang:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(osChungang.name)
  end,
  on_use = function (self, event, target, player, data)
    player.room:askToUseActiveSkill(player, {
      skill_name = "os__chungang",
      cancelable = false,
      prompt = "#os__chungang-active",
    })
  end
})

osChungang:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return
      not (data.extra_data or {}).osChungangIds and
      table.find(Card:getIdList(data.card), function(id)
        return Fk:getCardById(id):getMark("@@os__chungang-inhand") > 0
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.osChungangIds = table.filter(Card:getIdList(data.card), function(id)
      return Fk:getCardById(id):getMark("@@os__chungang-inhand") > 0
    end)
  end,
})

osChungang:addEffect(fk.CardUsing, {
  anim_type = "negative",
  trigger_times = function(self, event, target, player, data)
    return
      type((data.extra_data or {}).osChungangIds) == "table" and
      #table.filter(Card:getIdList(data.card), function(id)
        return table.contains(data.extra_data.osChungangIds, id)
      end) or
      0
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osChungang.name) and player ~= target and not target:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local skillName = osChungang.name
    local room = player.room
    room:doIndicate(player, { target })
    room:askToDiscard(target, {
      prompt = "#os__chungang-discard:" .. player.id,
      include_equip = true,
      skill_name = skillName,
      min_num = 1,
      max_num = 1,
      cancelable = false,
    })
  end,
})

return osChungang
