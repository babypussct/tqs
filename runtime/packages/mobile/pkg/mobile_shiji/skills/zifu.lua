local zifu = fk.CreateSkill {
  name = "zifu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zifu"] = "自缚",
  [":zifu"] = "锁定技，出牌阶段结束时，若你本阶段未使用牌，你本回合手牌上限-1并移除你所有的“备”。",

  ["$zifu1"] = "有心无力，请罪愿降。",
  ["$zifu2"] = "舆榇自缚，只求太傅开恩！",
}

zifu:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zifu.name) and player.phase == Player.Play and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
    player.room:setPlayerMark(player, "@$wangling_bei", 0)
  end,
})

return zifu
