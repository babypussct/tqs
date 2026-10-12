local kongsheng = fk.CreateSkill {
  name = "m_ex__kongsheng",
  expand_pile = "$m_ex__zhoufei_harp",
}

Fk:loadTranslationTable {
  ["m_ex__kongsheng"] = "箜声",
  [":m_ex__kongsheng"] = "准备阶段，或你失去及回复体力后，你可以将当前回合角色任意张牌置于其武将牌上；" ..
      "其结束阶段，你可以使用其中一张牌，其获得其余的牌。",

  ["#m_ex__kongsheng-invoke"] = "箜声：你可以将 %dest 的任意张牌置为“箜”",
  ["$m_ex__zhoufei_harp"] = "箜",
  ["#m_ex__kongsheng-use"] = "箜声：你可以使用“箜”中一张牌，%dest 获得其余的牌",

  ["$m_ex__kongsheng1"] = "弦动人欲醉，声闻一时醒。",
  ["$m_ex__kongsheng2"] = "静弹箜篌引，寄我悠悠心。",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
          skill_name = kongsheng.name,
          prompt = "#m_ex__kongsheng-invoke::" .. room.current.id,
        }) then
      event:setCostData(self, { tos = { room.current } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      min = 1,
      max = #room.current:getCardIds("he"),
      target = room.current,
      flag = "he",
      skill_name = kongsheng.name,
    })
    room.current:addToPile("$m_ex__zhoufei_harp", cards, false, kongsheng.name, player)
  end,
}

kongsheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kongsheng.name) and player.phase == Player.Start and
        not player:isNude()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

kongsheng:addEffect(fk.HpLost, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
        target == player and
        player:hasSkill(kongsheng.name) and
        player.room.current and
        player.room.current:isAlive() and
        not player.room.current:isNude()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

kongsheng:addEffect(fk.HpRecover, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
        target == player and
        player:hasSkill(kongsheng.name) and
        player.room.current and
        player.room.current:isAlive() and
        not player.room.current:isNude()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

kongsheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kongsheng.name) and target.phase == Player.Finish and
        #target:getPile("$m_ex__zhoufei_harp") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToUseRealCard(player, {
      pattern = tostring(Exppattern { id = target:getPile("$m_ex__zhoufei_harp") }),
      skill_name = kongsheng.name,
      prompt = "#m_ex__kongsheng-use::" .. target.id,
      cancelable = true,
      expand_pile = target:getPile("$m_ex__zhoufei_harp"),
    })
    if not target.dead then
      room:obtainCard(target, target:getPile("$m_ex__zhoufei_harp"), false, fk.ReasonJustMove, player, kongsheng.name,
        nil, { player, target })
    end
  end,
})

kongsheng:addLoseEffect(function(self, player, is_death)
  local room = player.room
  local getPlayers = table.filter(room.alive_players, function(p)
    return #p:getPile("$m_ex__zhoufei_harp") > 0
  end)
  for _, p in ipairs(getPlayers) do
    room:obtainCard(p, p:getPile("$m_ex__zhoufei_harp"), false, fk.ReasonJustMove, player, kongsheng.name, nil, p)
  end
end)
return kongsheng
