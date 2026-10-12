local qiluan = fk.CreateSkill {
  name = "sp__qiluan",
}

Fk:loadTranslationTable{
  ["sp__qiluan"] = "戚乱",
  [":sp__qiluan"] = "一名角色的回合结束时，若你于此回合内杀死过角色，你可以摸三张牌。",

  ["$sp__qiluan1"] = "待我召吾兄入宫，谁敢不从？",
  ["$sp__qiluan2"] = "本后自有哥哥在外照应，有什么好担心的！",
}

qiluan:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiluan.name) and
      #player.room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
        return e.data.killer == player
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, qiluan.name)
  end,
})

return qiluan
