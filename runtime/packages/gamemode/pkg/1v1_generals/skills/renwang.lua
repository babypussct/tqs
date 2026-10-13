local renwang = fk.CreateSkill {
  name = "v11__renwang",
}

Fk:loadTranslationTable{
  ["v11__renwang"] = "仁望",
  [":v11__renwang"] = "当对手于其出牌阶段内对你使用【杀】或普通锦囊牌时，若本阶段你已成为过上述牌的目标，你可以弃置其一张牌。",

  ["$v11__renwang1"] = "忍无可忍，无需再忍！",
  ["$v11__renwang2"] = "休怪我无情了！",
}

renwang:addEffect(fk.CardUsing, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(renwang.name) and target ~= player and not target:isNude() and target.phase == Player.Play and
      table.contains(data.tos, player) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from == target and use ~= data and (use.card.trueName == "slash" or use.card:isCommonTrick())
          and table.contains(use.tos, player)
      end, Player.HistoryPhase) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "he",
      skill_name = renwang.name,
    })
    room:throwCard(id, renwang.name, target, player)
  end,
})

return renwang
