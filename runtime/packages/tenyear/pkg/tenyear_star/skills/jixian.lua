local jixian = fk.CreateSkill({
  name = "jixianz",
})

Fk:loadTranslationTable{
  ["jixianz"] = "机先",
  [":jixianz"] = "若你回合的第一个出牌阶段没有使用基本和锦囊牌，则弃牌阶段结束后你可以执行一个额外的出牌阶段，此阶段你不能使用装备牌。",

  ["$jixianz1"] = "卸甲疾行，敌虽远亦一夕可至。",
  ["$jixianz2"] = "用兵如水，无常势亦无常形。",
}

jixian:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Discard and player:hasSkill(jixian.name) then
      local room = player.room
      local triggerable = false
      room.logic:getEventsOfScope(GameEvent.Phase, 1, function(e)
        if e.data.phase == Player.Play then
          triggerable = true
          room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e2)
            if e2.id < e.end_id then
              local use = e2.data
              if use.from == player and use.card.type ~= Card.TypeEquip then
                triggerable = false
                return true
              end
            end
          end, e.id)
          return true
        end
      end, Player.HistoryTurn)
      return triggerable
    end
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraPhase(Player.Play, jixian.name)
  end,
})

jixian:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.reason == jixian.name
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "jixian_extra-phase", 1)
  end,
})

jixian:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("jixian_extra-phase") > 0 and card.type == Card.TypeEquip
  end,
})

return jixian
