
local fuli = fk.CreateSkill {
  name = "os_heg__fuli",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os_heg__fuli"] = "伏枥",
  [":os_heg__fuli"] = "限定技，当你处于濒死状态时，你可以将体力值回复至X点（X为全场势力数）。若如此做，你翻面。",

  ["$os_heg__fuli1"] = "今天是个拼命的好日子，哈哈哈哈！",
  ["$os_heg__fuli2"] = "有老夫在，蜀汉就不会倒下！",
}

local H = require "packages.hegemony.util"

fuli:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fuli.name) and
      player.dying and player:usedSkillTimes(fuli.name, Player.HistoryGame) == 0 then
      local n = 0
      for _, _ in pairs(H.getKingdomPlayersNum(player.room)) do
        n = n + 1
      end
      return player.hp < n
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, _ in pairs(H.getKingdomPlayersNum(room)) do
      n = n + 1
    end
    room:recover{
      who = player,
      num = n - player.hp,
      recoverBy = player,
      skillName = fuli.name,
    }
    if not player.dead then
      player:turnOver()
    end
  end,
})

return fuli
