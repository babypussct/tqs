
local xingshi = fk.CreateSkill {
  name = "m_heg__xingshi",
}

Fk:loadTranslationTable{
  ["m_heg__xingshi"] = "兴师",
  [":m_heg__xingshi"] = "准备阶段，你可以消耗1个“弘”，令一名与你距离1以内的角色必须执行一次军令。",

  ["#m_heg__xingshi-choose"] = "兴师：你可以消耗1个“弘”，令一名角色必须执行一次军令",

  ["$m_heg__xingshi1"] = "传朕旨意，出兵北伐！",
  ["$m_heg__xingshi2"] = "朕且统朝安政，外事咸决相父。",
  ["$m_heg__xingshi3"] = "君臣同心，功成即在今日！",
  ["$m_heg__xingshi4"] = "今兵甲己足，三军当复中原矣！",
}

local H = require "packages.hegemony.util"

xingshi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingshi.name) and player.phase == Player.Start and
      player:getMark("@m_heg__huihong") > 0 and
      table.find(player.room:getAlivePlayers(false), function (p)
        return p:compareDistance(player, 1, "<=")
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(false), function (p)
      return p:compareDistance(player, 1, "<=")
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_heg__xingshi-choose",
      skill_name = xingshi.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@m_heg__huihong", 1)
    local to = event:getCostData(self).tos[1]
    local command = H.askToStartCommand(player, {
      skill_name = xingshi.name,
    })
    H.Command({
      tos = { to },
      skillName = xingshi.name,
      command = command[1],
      from = player,
      forced = true,
    })
  end,
})

return xingshi
