
local jilix = fk.CreateSkill {
  name = "ld__jilix",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__jilix"] = "寄篱",
  [":ld__jilix"] = "锁定技，当你成为红色基本牌或红色普通锦囊牌的唯一目标后，你选择令此牌额外结算一次或移除此武将牌。",

  ["#ld__jilix-choice"] = "寄篱：你成为%arg目标，请选择一项",
  ["ld__jilix_effect"] = "额外结算一次",
  ["ld__jilix_remove"] = "移除此武将牌",

  ["$ld__jilix1"] = "处处受制于人，难施拳脚。",
  ["$ld__jilix2"] = "寄居人下，终是气短！",
}

local H = require "packages.hegemony.util"

jilix:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jilix.name) and
      data:isOnlyTarget(player) and
      data.card.color == Card.Red and (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "ld__jilix_effect", "ld__jilix_remove" },
      skill_name = jilix.name,
      prompt = "#ld__jilix-choice:::"..data.card:toLogString(),
    })
    if choice == "ld__jilix_effect" then
      data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
    else
      if H.inGeneralSkills(player, jilix.name) == "m" then
        H.removeGeneral(player, false)
      elseif H.inGeneralSkills(player, jilix.name) == "d" then
        H.removeGeneral(player, true)
      end
    end
  end,
})

return jilix
