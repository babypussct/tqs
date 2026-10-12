
local huimeng = fk.CreateSkill {
  name = "m_heg__huimeng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["m_heg__huimeng"] = "会盟",
  [":m_heg__huimeng"] = "锁定技，有存活角色的势力数变化时，你摸一张牌。",

  ["$m_heg__huimeng1"] = "诸公各怀己心，今当共济国难！",
  ["$m_heg__huimeng2"] = "凡我同盟，必无二志！",
  ["$m_heg__huimeng3"] = "今弄时之风云，当联天下英杰！",
  ["$m_heg__huimeng4"] = "九州豪杰，当助吾成之大业！",
}

local H = require "packages.hegemony.util"

huimeng:addEffect(fk.GeneralRevealed, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(huimeng.name) and
      not table.find(player.room:getOtherPlayers(target, false), function (p)
        return H.compareKingdomWith(p, target)
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, huimeng.name)
  end,
})

huimeng:addEffect(fk.GeneralHidden, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(huimeng.name) and
      not table.find(player.room:getOtherPlayers(target, false), function (p)
        return H.compareExpectedKingdomWith(p, target)
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, huimeng.name)
  end,
})

huimeng:addEffect(fk.Death, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(huimeng.name) and
      not table.find(player.room.alive_players, function (p)
        return H.compareKingdomWith(p, target)
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, huimeng.name)
  end,
})

return huimeng
