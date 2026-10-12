local zhengrong = fk.CreateSkill{
  name = "ofl_heg__zhengrong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ofl_heg__zhengrong"] = "征荣",
  [":ofl_heg__zhengrong"] = "锁定技，当你造成/受到伤害时，若场上没有与受伤角色/伤害来源势力相同的其他角色，此伤害+1。",

  ["$ofl_heg__zhengrong1"] = "东征高句丽，保辽东安稳。",
  ["$ofl_heg__zhengrong2"] = "跨海东征，家国俱荣。",
}

local H = require "packages.hegemony.util"

zhengrong:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengrong.name) and
      not table.find(player.room:getOtherPlayers(data.to, false), function(p)
        return H.compareKingdomWith(p, data.to)
      end)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

zhengrong:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengrong.name) and data.from and
      not table.find(player.room:getOtherPlayers(data.from, false), function(p)
        return H.compareKingdomWith(p, data.from)
      end)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return zhengrong
