
local xiongchi = fk.CreateSkill{
  name = "m_heg__xiongchi",
}

Fk:loadTranslationTable{
  ["m_heg__xiongchi"] = "雄驰",
  [":m_heg__xiongchi"] = "你每回合首次造成伤害后，可以令受伤角色对你的一名同势力角色造成1点虚拟伤害。",

  ["#m_heg__xiongchi-invoke"] = "雄驰：你可以令 %dest 对你一名同势力角色造成1点虚拟伤害",

  ["$m_heg__xiongchi1"] = "不受此谤，操安能以血补天哉？",
  ["$m_heg__xiongchi2"] = "天下之罪，在孤而已；天下之功，亦在孤一人！",
  ["$m_heg__xiongchi3"] = "今既无太平可治，孤自当为雄。",
  ["$m_heg__xiongchi4"] = "若以天下相较，何怜千万白骨！",
}

local H = require "packages.hegemony.util"

xiongchi:addEffect(fk.Damage, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(xiongchi.name) and player:usedSkillTimes(xiongchi.name, Player.HistoryTurn) == 0 and
      not data.to.dead then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player
      end)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end),
      min_num = 1, max_num = 1,
      skill_name = xiongchi.name,
      prompt = "#m_heg__xiongchi-invoke::"..data.to.id,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos, audio_index = tos[1] == player and table.random({1, 2}) or table.random({3, 4}) })
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:damage{
      from = data.to,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = xiongchi.name,
      isVirtualDMG = true,
    }
  end,
})

return xiongchi
