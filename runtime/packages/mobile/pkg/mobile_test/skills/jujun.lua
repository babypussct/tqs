local jujun = fk.CreateSkill{
  name = "mobile__jujun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__jujun"] = "据峻",
  [":mobile__jujun"] = "锁定技，你成为过牌的目标且体力值变化过的阶段结束时，你视为使用一张【万箭齐发】。",

  ["$mobile__jujun"] = "我等万箭齐下，敌军安可上得山来！",
}

jujun:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jujun.name) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return table.contains(e.data.tos, player)
      end, Player.HistoryPhase) > 0 and
      #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        return e.data.who == player
      end, Player.HistoryPhase) > 0 and
      player:canUse(Fk:cloneCard("archery_attack"))
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("archery_attack")
    card.skillName = jujun.name
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not player:isProhibited(p, card)
    end)
    if #targets > 0 then
      room:useVirtualCard("archery_attack", nil, player, targets, jujun.name)
    end
  end,
})

return jujun