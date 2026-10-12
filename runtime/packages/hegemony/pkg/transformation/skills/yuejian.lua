
local yuejian = fk.CreateSkill{
  name = "ld__yuejian",
  tags = {Skill.Compulsory}
}

Fk:loadTranslationTable{
  ["ld__yuejian"] = "约俭",
  [":ld__yuejian"] = "锁定技，所有与你势力相同的角色的手牌上限+X（X为其已损失的体力值）。",

  ["$ld__yuejian1"] = "吾母仪天下，于节俭处当率先垂范。",
  ["$ld__yuejian2"] = "取上为贪，取下为伪，妾则取其中者。",
}
local H = require "packages.hegemony.util"

yuejian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return H.compareKingdomWith(player, target) and player:hasSkill(yuejian.name) and target.phase == Player.Discard
    and player.room.current == target
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, { target.id })
    room:addPlayerMark(target, "_yuejian_maxcard-turn", 1)
  end,
})

yuejian:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:getMark("_yuejian_maxcard-turn") > 0 then
      return player:getLostHp()
    end
  end
})

return yuejian
