local didong = fk.CreateSkill {
  name = "jiange__didong"
}

Fk:loadTranslationTable{
  ["jiange__didong"] = "地动",
  [":jiange__didong"] = "结束阶段，你可以令随机一名敌方角色翻面。",

  ["#jiange__didong-invoke"] = "地动：是否令随机一名敌方角色翻面？",
}

didong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(didong.name) and player.phase == Player.Finish and
      #player:getEnemies() > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = didong.name,
      prompt = "#jiange__didong-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:tableRandomPick(player:getEnemies())
    room:doIndicate(player, {to})
    to:turnOver()
  end,
})

return didong
