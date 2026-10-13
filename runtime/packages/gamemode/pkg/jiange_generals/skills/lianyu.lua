local lianyu = fk.CreateSkill {
  name = "jiange__lianyu",
}

Fk:loadTranslationTable{
  ["jiange__lianyu"] = "炼狱",
  [":jiange__lianyu"] = "结束阶段，你可以翻面，对所有敌方角色各造成1点火焰伤害。",

  ["#jiange__lianyu-invoke"] = "炼狱：是否翻面并对所有敌方角色各造成1点火焰伤害？",
}

lianyu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianyu.name) and player.phase == Player.Finish and
      #player:getEnemies() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = lianyu.name,
      prompt = "#jiange__lianyu-invoke",
    }) then
      local tos = player:getEnemies()
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:turnOver()
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:isEnemy(player) and not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = lianyu.name,
        }
      end
    end
  end,
})

return lianyu
