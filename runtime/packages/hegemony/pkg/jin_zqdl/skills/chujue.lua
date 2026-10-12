local chujue = fk.CreateSkill {
  name = "heg__chujue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["heg__chujue"] = "除绝",
  [":heg__chujue"] = "锁定技，你对有角色死亡的势力的角色使用牌无次数限制且不能被这些角色响应。",

  ["$heg__chujue1"] = "一箭之仇，十年不忘！",
  ["$heg__chujue2"] = "此仇不报，怨恨难消！",
}

local H = require "packages.hegemony.util"

chujue:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chujue.name) and
      table.find(data.tos, function(p)
        return table.find(player.room.players, function (q)
          return q.dead and H.compareKingdomWith(p, q, false)
        end) ~= nil
      end)
  end,
  on_use = function(self, event, target, player, data)
    data.extraUse = true
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      if table.find(player.room.players, function (q)
          return q.dead and H.compareKingdomWith(p, q, false)
        end) then
        table.insertIfNeed(data.disresponsiveList, p)
      end
    end
  end,
})

chujue:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    if player:hasSkill(chujue.name) and card and to then
      if table.find(Fk:currentRoom().players, function (p)
        return p.dead and H.compareKingdomWith(to, p, false)
      end) then
        return true
      end
    end
  end,
})

return chujue
