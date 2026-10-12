
local zhulan = fk.CreateSkill{
  name = "heg__zhulan",
}

Fk:loadTranslationTable{
  ["heg__zhulan"] = "助澜",
  [":heg__zhulan"] = "当一名其他角色受到伤害时，若伤害来源与其势力相同，你可以弃置一张牌令此伤害+1。",

  ["#heg__zhulan-invoke"] = "助澜：你可以弃置一张牌，令 %dest 受到的伤害+1",
}

local H = require "packages.hegemony.util"

zhulan:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(zhulan.name) and
      data.from and H.compareKingdomWith(data.from, target, false) and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zhulan.name,
      cancelable = true,
      prompt = "#heg__zhulan-invoke::" .. target.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, zhulan.name, player, player)
    data:changeDamage(1)
  end,
})

return zhulan
