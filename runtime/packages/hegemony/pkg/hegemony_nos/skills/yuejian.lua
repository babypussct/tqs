
local yuejian = fk.CreateSkill{
  name = "nos_heg__yuejian",
  tags = { Skill.Compulsory }
}

Fk:loadTranslationTable{
  ["nos_heg__yuejian"] = "约俭",
  [":nos_heg__yuejian"] = "锁定技，与你势力相同的角色弃牌阶段开始时，若其本回合处于与你势力相同状态时未使用牌指定过其他势力的角色为目标，"..
  "则该角色本回合手牌上限等同于其体力上限。",

  ["$nos_heg__yuejian1"] = "吾母仪天下，于节俭处当率先垂范。",
  ["$nos_heg__yuejian2"] = "取上为贪，取下为伪，妾则取其中者。",
}

local H = require "packages.hegemony.util"

yuejian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return H.compareKingdomWith(player, target) and player:hasSkill(yuejian.name) and target.phase == Player.Discard and
      target:getMark("nos_heg__yuejian_nullified-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "nos_heg__yuejian-turn", 1)
  end,
})

yuejian:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return H.compareKingdomWith(target, player) and target == player.room:getCurrent() and
      not H.compareKingdomWith(data.to, target)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "nos_heg__yuejian_nullified-turn", 1)
  end,
})

yuejian:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:getMark("nos_heg__yuejian-turn") > 0 then
      return player.maxHp
    end
  end
})

return yuejian
