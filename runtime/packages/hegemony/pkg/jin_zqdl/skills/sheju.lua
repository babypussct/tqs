local sheju = fk.CreateSkill{
  name = "heg__shejus",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["heg__shejus"] = "慑惧",
  [":heg__shejus"] = "锁定技，当其他角色明置武将牌后，若其势力与你相同，你回复1点体力，然后弃置所有手牌。",
}

local H = require "packages.hegemony.util"

sheju:addEffect(fk.GeneralRevealed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sheju.name) and target ~= player and
      H.compareKingdomWith(player, target, false) and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover {
      who = player,
      num = 1,
      skillName = sheju.name,
      recoverBy = player,
    }
    if not player.dead then
      player:throwAllCards("h", sheju.name)
    end
  end
})

return sheju
