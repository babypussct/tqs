local yangwu = fk.CreateSkill {
  name = "ol_fd__yangwu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_fd__yangwu"] = "扬武",
  [":ol_fd__yangwu"] = "锁定技，准备阶段，你对所有其他角色各造成1点伤害，然后你失去1点体力。",

  ["$ol_fd__yangwu1"] = "袭夺之势，如狼噬骨。",
  ["$ol_fd__yangwu2"] = "引吾至此，怎能不袭掠之？"
}

yangwu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yangwu.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, {tos = player.room:getOtherPlayers(player)})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = yangwu.name,
        }
      end
    end
    if player.dead then return end
    room:loseHp(player, 1, yangwu.name)
  end,
})

return yangwu
