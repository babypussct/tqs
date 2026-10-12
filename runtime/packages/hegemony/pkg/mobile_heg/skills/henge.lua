
local henge = fk.CreateSkill{
  name = "m_heg__henge",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__henge"] = "衡轭",
  [":m_heg__henge"] = "<a href='m_heg_summon'>阵法技</a>，锁定技，与你处于同一<a href='heg_formation_href'>队列</a>的其他角色"..
  "获得你“义从”距离修正的相同效果（每项至多为2）。",

  ["m_heg_summon"] = "手杀阵法技移除了“阵法召唤”效果",
}

local H = require "packages.hegemony.util"

henge:addEffect("distance", {
  correct_func = function (self, from, to, card)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if H.inFormationRelation(from, p) and p ~= from and p:getMark("@m_heg__yicong_from-round") > 0 then
        n = n - math.min(p:getMark("@m_heg__yicong_from-round"), 2)
      end
      if H.inFormationRelation(to, p) and p ~= to and p:getMark("@m_heg__yicong_to-round") > 0 then
        n = n + math.min(p:getMark("@m_heg__yicong_to-round"), 2)
      end
    end
    return n
  end,
})

return henge

