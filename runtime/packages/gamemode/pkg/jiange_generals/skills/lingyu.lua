local lingyu = fk.CreateSkill {
  name = "jiange__lingyu",
}

Fk:loadTranslationTable{
  ["jiange__lingyu"] = "灵愈",
  [":jiange__lingyu"] = "结束阶段，你可以翻面，然后令其他友方角色各回复1点体力。",

  ["#jiange__lingyu-invoke"] = "灵愈：是否翻面，令其他友方角色各回复1点体力？",
}

lingyu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lingyu.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = lingyu.name,
      prompt = "#jiange__lingyu-invoke",
    }) then
      event:setCostData(self, {tos = player:getFriends(false)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:turnOver()
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and p:isFriend(player) and p:isWounded() then
        room:recover{
          who = p,
          num = 1,
          recoverBy = player,
          skillName = lingyu.name,
        }
      end
    end
  end,
})

return lingyu
