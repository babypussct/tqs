
local qunchou = fk.CreateSkill {
  name = "ol_heg__qunchou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ol_heg__qunchou"] = "群仇",
  [":ol_heg__qunchou"] = "锁定技，你杀死一名角色，或同势力角色杀死你的奖惩改为变更暗置的副将。",

  ["$ol_heg__qunchou1"] = "何进跋扈，谋诛之，方能辅立新君。",
  ["$ol_heg__qunchou2"] = "我尽忠先帝，尔曹怎敢如此！",
}

local H = require "packages.hegemony.util"

qunchou:addEffect(fk.BuryVictim, {
  can_trigger = function(self, event, target, player, data)
    if target == player then
      return player:hasSkill(qunchou.name, false, true) and
        data.killer and H.compareKingdomWith(player, data.killer) and not data.killer.dead
    else
      return player:hasSkill(qunchou.name) and data.killer == player
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local deathEvent = room.logic:getCurrentEvent():findParent(GameEvent.Death, true).data
    deathEvent.extra_data = deathEvent.extra_data or {}
    deathEvent.extra_data.ignorePunishment = true
    if data.killer.deputyGeneral == "anjiang" then
      H.transformGeneral(room, data.killer, false, true, 3)
    end
  end,
})

return qunchou
