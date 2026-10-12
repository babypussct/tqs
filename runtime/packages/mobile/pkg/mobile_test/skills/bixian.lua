local bixian = fk.CreateSkill{
  name = "bixian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["bixian"] = "壁险",
  [":bixian"] = "锁定技，你成为过牌的目标且体力值未变化过的阶段结束时，你视为使用一张【决斗】。",

  ["#bixian-use"] = "壁险：请视为使用一张【决斗】",

  ["$bixian"] = "今日形势危急，少不得要出全力！",
}

bixian:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(bixian.name) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return table.contains(e.data.tos, player)
      end, Player.HistoryPhase) > 0 and
      #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        return e.data.who == player
      end, Player.HistoryPhase) == 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:askToUseVirtualCard(player, {
      name = "duel",
      skill_name = bixian.name,
      prompt = "#bixian-use",
      cancelable = false,
    })
  end,
})

return bixian