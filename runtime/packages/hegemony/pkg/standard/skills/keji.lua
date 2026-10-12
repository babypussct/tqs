local keji = fk.CreateSkill{
  name = "hs__keji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hs__keji"] = "克己",
  [":hs__keji"] = "锁定技，弃牌阶段开始时，若你未于出牌阶段内使用过颜色不同的牌，则你于此回合内手牌上限+4。",

  ["$hs__keji1"] = "谨慎为妙。",
  ["$hs__keji2"] = "时机未到。",
}

keji:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(keji.name) and player.phase == Player.Discard then
      local phase_events = player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        return e.data.who == player and e.data.phase == Player.Play
      end, Player.HistoryTurn)
      if #phase_events == 0 then
        return true
      else
        local colors = {}
        player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          if e.data.from == player and e.data.card.color ~= Card.NoColor and
            table.find(phase_events, function (phase)
              return e.id > phase.id and e.id < phase.end_id
            end) then
            table.insertIfNeed(colors, e.data.card.color)
          end
        end, Player.HistoryTurn)
        return #colors <= 1
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 4)
  end
})

return keji
