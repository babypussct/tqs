local kuangcai = fk.CreateSkill{
  name = "ty_heg__kuangcai",
  tags = {Skill.Compulsory},
}
kuangcai:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(kuangcai.name) and player.phase == Player.Discard then
      local used = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from == player
      end, Player.HistoryTurn) > 0
      if not used then
        event:setCostData(self, {choice = "noUsed"})
        return true
      elseif #player.room.logic:getActualDamageEvents(1, function(e) return e.data.from == player end) == 0 then
        event:setCostData(self, {choice = "used"})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(kuangcai.name)
    if event:getCostData(self).choice == "noUsed" then
      room:notifySkillInvoked(player, kuangcai.name, "support")
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      room:notifySkillInvoked(player, kuangcai.name, "negative")
      room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
    end
    room:broadcastProperty(player, "MaxCards")
  end,
})
kuangcai:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(kuangcai.name) and player.phase ~= Player.NotActive
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(kuangcai.name) and player.phase ~= Player.NotActive
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__kuangcai"] = "狂才",
  [":ty_heg__kuangcai"] = "锁定技，①你的回合内，你使用牌无距离和次数限制。②弃牌阶段开始时，若你本回合：没有使用过牌，你的手牌上限+1；使用过牌且没有造成伤害，你手牌上限-1。",

  ["$ty_heg__kuangcai1"] = "耳所瞥闻，不忘于心。",
  ["$ty_heg__kuangcai2"] = "吾焉能从屠沽儿耶？",
}

return kuangcai
