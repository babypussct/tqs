
local yicheng = fk.CreateSkill {
  name = "nos_heg__yicheng",
}

Fk:loadTranslationTable{
  ["nos_heg__yicheng"] = "疑城",
  [":nos_heg__yicheng"] = "当与你势力相同的角色成为【杀】的目标后，你可以令其摸一张牌，然后其弃置一张牌。",

  ["#nos_heg__yicheng-invoke"] = "疑城：是否令 %dest 摸一张牌并弃置一张牌？",

  ["$nos_heg__yicheng1"] = "不怕死，就尽管放马过来！",
  ["$nos_heg__yicheng2"] = "待末将布下疑城，以退曹贼。",
}

local H = require "packages.hegemony.util"

yicheng:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yicheng.name) and data.card.trueName == "slash" and
      H.compareKingdomWith(player, target) and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yicheng.name,
      prompt = "#nos_heg__yicheng-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1, yicheng.name)
    if not target.dead then
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = yicheng.name,
        cancelable = false,
      })
    end
  end,
})

return yicheng
