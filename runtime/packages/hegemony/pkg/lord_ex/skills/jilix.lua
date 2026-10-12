local jilix = fk.CreateSkill {
  name = "ld__jilix",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__jilix"] = "寄篱",
  [":ld__jilix"] = "锁定技，当你成为红色基本牌或红色普通锦囊牌的唯一目标后，你令此牌额外结算一次；"..
  "当你于一个阶段内第二次受到伤害时，你防止此伤害，然后移除此武将牌。",

  ["$ld__jilix1"] = "处处受制于人，难施拳脚。",
  ["$ld__jilix2"] = "寄居人下，终是气短！",
}

local H = require "packages.hegemony.util"

jilix:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jilix.name) and data.card.color == Card.Red  and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and data:isOnlyTarget(player)
  end,
  on_use = function(self, event, target, player, data)
    data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
  end,
})

jilix:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jilix.name) and
      #player.room.logic:getActualDamageEvents(2, function(e)
        return e.data.to == player
      end, Player.HistoryPhase) == 1
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    local isDeputy = H.inGeneralSkills(player, jilix.name)
    if isDeputy then
      H.removeGeneral(player, isDeputy == "d")
    end
  end,
})

return jilix
