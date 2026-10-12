
local zhulian = fk.CreateSkill{
  name = "ol_heg__zhulian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_heg__zhulian"] = "诛连",
  [":ol_heg__zhulian"] = "锁定技，你的回合内，于本回合使用过【桃】，或成为过【桃】目标的角色受到的伤害+1。",

  ["$ol_heg__zhulian1"] = "所取者，恪也；余者，尽族。",
  ["$ol_heg__zhulian2"] = "沾亲带故，便是最大的罪过。",
}

zhulian:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhulian.name) and player.room:getCurrent() == player and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.card.trueName == "peach" and (e.data.from == data.to or table.contains(e.data.tos, data.to))
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return zhulian
