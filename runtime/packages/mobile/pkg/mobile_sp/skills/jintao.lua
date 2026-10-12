local jintao = fk.CreateSkill {
  name = "mobile__jintao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__jintao"] = "进讨",
  [":mobile__jintao"] = "锁定技，你使用【杀】无距离限制且次数+1。你出牌阶段使用的第一张【杀】不可响应，第二张【杀】伤害值基数+1。",

  ["$mobile__jintao1"] = "引兵进讨，断不负丞相之望！",
  ["$mobile__jintao2"] = "举兵出征，以期北伐建功！",
}

jintao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jintao.name) then
      local times = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 3, function (e)
        return e.data.from == player and e.data.card.trueName == "slash"
      end, Player.HistoryPhase)
      if data.card.trueName == "slash" and player.phase == Player.Play and times <= 2 then
        event:setCostData(self, {choice = times})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local num = event:getCostData(self).choice
    if num == 1 then
      data.disresponsiveList = table.simpleClone(player.room.players)
    elseif num == 2 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

jintao:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(jintao.name) and skill.trueName == "slash_skill") and 1 or 0
  end,
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(jintao.name) and skill.trueName == "slash_skill"
  end,
})

return jintao
