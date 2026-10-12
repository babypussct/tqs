
local dufu = fk.CreateSkill{
  name = "heg__dufu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["heg__dufu"] = "独夫",
  [":heg__dufu"] = "锁定技，若场上没有与你势力相同的其他角色，你造成的伤害+1且摸牌阶段多摸两张牌。",
}

local H = require "packages.hegemony.util"

dufu:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dufu.name) and
      not table.find(player.room:getOtherPlayers(player, false), function (p)
        return H.compareKingdomWith(p, player)
      end)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

dufu:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dufu.name) and
      not table.find(player.room:getOtherPlayers(player, false), function (p)
        return H.compareKingdomWith(p, player)
      end)
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

return dufu
