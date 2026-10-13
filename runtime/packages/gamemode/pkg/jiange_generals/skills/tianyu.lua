local tianyu = fk.CreateSkill {
  name = "jiange__tianyu",
}

Fk:loadTranslationTable{
  ["jiange__tianyu"] = "天狱",
  [":jiange__tianyu"] = "结束阶段，你可以横置所有敌方角色。",

  ["#jiange__tianyu-invoke"] = "天狱：是否横置所有敌方角色？",
}

tianyu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianyu.name) and player.phase == Player.Finish and
      table.find(player:getEnemies(), function (p)
        return not p.chained
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = tianyu.name,
      prompt = "#jiange__tianyu-invoke",
    }) then
      local tos = player:getEnemies()
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("lianhuan")
    local targets = table.filter(player:getEnemies(), function (p)
      return not p.chained
    end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.chained and not p.dead then
        p:setChainState(true)
      end
    end
  end,
})

return tianyu
