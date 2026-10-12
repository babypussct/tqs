local duanshi = fk.CreateSkill {
  name = "ofl_heg__duanshi",
  tags = { Skill.MainPlace, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ofl_heg__duanshi"] = "断势",
  [":ofl_heg__duanshi"] = "主将技，锁定技，你计算体力上限时减少1个单独的阴阳鱼。一名角色因杀死与你势力相同的其他角色执行奖惩而摸牌时，"..
  "其少摸一张牌，然后你摸一张牌。",
}

local H = require "packages.hegemony.util"

duanshi:addEffect(fk.BeforeDrawCard, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(duanshi.name) and data.skillName == "kill" then
      local death = player.room.logic:getCurrentEvent():findParent(GameEvent.Death, true).data
      return H.compareKingdomWith(player, death.who)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.num = data.num - 1
  end,
})

duanshi:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(duanshi.name) and
      data.killer and data.killer ~= player and H.compareKingdomWith(player, target)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, duanshi.name)
  end,
})

return duanshi
