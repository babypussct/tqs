local fengshi = fk.CreateSkill{
  name = "fengshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengshi"] = "锋矢",
  [":fengshi"] = "阵法技，若你是围攻角色且处于<a href='heg_formation_href'>队列</a>，你对被围攻角色使用的【杀】伤害+X（X为你队列的角色数）。",

  ["#fengshi-discard"] = "锋矢：弃置装备区里的一张牌",

  ["$fengshi1"] = "大军压境，还不卸甲受降！",
  ["$fengshi2"] = "放下兵器，饶你不死！",
}

local H = require "packages.hegemony.util"

fengshi:addEffect("arraysummon", {
  array_type = "siege",
})

fengshi:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasShownSkill(fengshi.name) and
      data.card and data.card.trueName == "slash" and
      H.inSiegeRelation(target, player, data.to) and #H.getFormationRelation(player) > 0
  end,
  on_use = function(self, event, target, player, data)
      data:changeDamage(1 + #H.getFormationRelation(player))
  end,
})

return fengshi
