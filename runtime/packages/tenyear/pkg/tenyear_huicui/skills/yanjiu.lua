local yanjiu = fk.CreateSkill {
  name = "yanjiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yanjiu"] = "厌酒",
  [":yanjiu"] = "锁定技，每轮结束时，你失去X点体力，若因此失去体力，你选择一名其他角色下次受到【杀】伤害+1，"..
  "若未因此失去体力，你回复1点体力（X为你本轮使用【酒】的数量）。",

  ["#yanjiu-choose"] = "厌酒：令一名其他角色下次受到【杀】伤害+1",
  ["@yanjiu"] = "受到杀伤害+",

  ["$yanjiu1"] = "喝喝喝！就知道喝！",
  ["$yanjiu2"] = "这入喉的酒，就是穿肠的药！"
}

yanjiu:addEffect(fk.RoundEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yanjiu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
      return e.data.from == player and e.data.card.trueName == "analeptic"
    end, Player.HistoryRound)
    if n > 0 then
      room:loseHp(player, n, yanjiu.name)
      if player.dead or #room:getOtherPlayers(player, false) == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#yanjiu-choose",
        skill_name = yanjiu.name,
        cancelable = false,
      })[1]
      room:setPlayerMark(to, "@yanjiu", 1)
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = yanjiu.name,
      }
    end
  end,
})

yanjiu:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@yanjiu") > 0 and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@yanjiu"))
    player.room:setPlayerMark(player, "@yanjiu", 0)
  end,
})

return yanjiu
