local fuli = fk.CreateSkill {
  name = "m_ex__fuli",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["m_ex__fuli"] = "伏枥",
  [":m_ex__fuli"] = "限定技，当你处于濒死状态时，你可以将你当前的体力值回复至X点（X为全场势力数）。然后若你的体力值全场唯一最高，你翻面。",

  ["$m_ex__fuli1"] = "未破敌军，岂可轻易服输？",
  ["$m_ex__fuli2"] = "看老夫再奋身一战！",
}

fuli:addEffect(fk.AskForPeaches, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuli.name) and player.dying and
      player:usedSkillTimes(fuli.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    table.forEach(room.alive_players, function(p)
      table.insertIfNeed(kingdoms, p.kingdom)
    end)
    room:recover({
      who = player,
      num = math.min(#kingdoms, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = fuli.name
    })
    if not player.dead and table.every(room.alive_players, function(p)
      return p == player or p.hp < player.hp
    end) then
      player:turnOver()
    end
  end,
})

fuli:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return fuli
