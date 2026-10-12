
local lizhong = fk.CreateSkill {
  name = "m_heg__lizhong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__lizhong"] = "励众",
  [":m_heg__lizhong"] = "锁定技，每轮结束时，你令同势力角色中，本轮造成过伤害且造成伤害最多的角色各获得1个“先驱”标记。",

  ["$m_heg__lizhong1"] = "非有众士同仇，何有今日之江山！",
  ["$m_heg__lizhong2"] = "千万人与朕同路，焉不为朕之手足。",
  ["$m_heg__lizhong3"] = "汉室已历四百载，今存亡俱在诸君。",
  ["$m_heg__lizhong4"] = "备再拜诸君，请诸君为汉一战。",
}

local H = require "packages.hegemony.util"

lizhong:addEffect(fk.RoundEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lizhong.name) then
      local count, max = {}, 0
      player.room.logic:getActualDamageEvents(1, function (e)
        if e.data.from and H.compareKingdomWith(e.data.from, player) then
          count[e.data.from] = (count[e.data.from] or 0) + e.data.damage
          max = math.max(max, count[e.data.from])
        end
      end, Player.HistoryRound)
      if max > 0 then
        local targets = {}
        for p, n in pairs(count) do
          if n == max and not p.dead then
            table.insert(targets, p)
          end
        end
        if #targets > 0 then
          player.room:sortByAction(targets)
          event:setCostData(self, { tos = targets })
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      H.addHegMark(p, "vanguard", 1)
    end
  end,
})

return lizhong
