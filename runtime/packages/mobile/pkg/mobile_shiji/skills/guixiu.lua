local guixiu = fk.CreateSkill {
  name = "mobile__guixiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__guixiu"] = "闺秀",
  [":mobile__guixiu"] = "锁定技，结束阶段，若你的体力值为奇数，则你摸一张牌，否则你回复1点体力。",

  ["$mobile__guixiu1"] = "身陷绝境，亦须秉端庄之姿。",
  ["$mobile__guixiu2"] = "纵吾身罹乱，焉能隳节败名。",
}

guixiu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guixiu.name) and player.phase == Player.Finish and
      ((player.hp % 2 == 1) or player:isWounded())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.hp % 2 == 1 then
      player:drawCards(1, guixiu.name)
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = guixiu.name
      }
    end
  end,
})

return guixiu
