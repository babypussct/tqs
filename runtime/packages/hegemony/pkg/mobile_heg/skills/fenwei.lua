
local fenwei = fk.CreateSkill{
  name = "m_heg__fenwei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__fenwei"] = "奋威",
  [":m_heg__fenwei"] = "锁定技，你首次明置此武将牌后，令所有同势力角色各获得一个“阴阳鱼”标记。",

  ["$m_heg__fenwei1"] = "",
  ["$m_heg__fenwei2"] = "",
}

local H = require "packages.hegemony.util"

fenwei:addEffect(fk.GeneralRevealed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(fenwei.name) then return false end
    if player:usedSkillTimes(fenwei.name, Player.HistoryGame) == 0 then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), fenwei.name) then return true end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if H.compareKingdomWith(player, p) then
        room:doIndicate(player, { p })
        H.addHegMark(p, "yinyangfish")
      end
    end
  end
})

return fenwei
