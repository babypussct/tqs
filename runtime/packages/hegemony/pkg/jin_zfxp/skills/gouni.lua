
local gouni = fk.CreateSkill {
  name = "heg__gouni",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["heg__gouni"] = "构逆",
  [":heg__gouni"] = "限定技，出牌阶段，你可以选择一名与你势力相同的其他角色，本局游戏除计算胜利外，其视为势力与你不同。",

  ["#heg__gouni"] = "构逆：选择一名角色，其视为势力与你不同！",
}

local H = require "packages.hegemony.util"

gouni:addEffect("active", {
  anim_type = "control",
  prompt = "#heg__gouni",
  can_use = function(self, player)
    return player:usedSkillTimes(gouni.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and H.compareKingdomWith(player, to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(player, gouni.name, target)
  end,
})

return gouni
