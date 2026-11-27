
local midao = fk.CreateSkill {
  name = "ld__midao",
}

Fk:loadTranslationTable {
  ["ld__midao"] = "米道",
  [":ld__midao"] = "每回合限一次，与你势力相同的角色造成属性伤害时，你可以摸两张牌或令此伤害+1。",

  ["#ld__midao-invoke"] = "米道：%src 对 %dest 造成伤害，你可以选择一项",
  ["ld__midao_damage"] = "伤害+1",

  ["$ld__midao1"] = "恩结天地，法惠八荒。",
  ["$ld__midao2"] = "行五斗米道，可知暖饱。",
}

local H = require "packages.hegemony.util"

midao:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(midao.name) and
      H.compareKingdomWith(player, target) and data.damageType ~= fk.NormalDamage and
      player:usedSkillTimes(midao.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "draw2", "ld__midao_damage" },
      skill_name = midao.name,
      prompt = "#ld__midao-invoke:"..target.id..":"..data.to.id,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = event:getCostData(self).choice
    if choice == "draw2" then
      player:drawCards(2, midao.name)
    else
      data:changeDamage(1)
    end
  end,
})

return midao
