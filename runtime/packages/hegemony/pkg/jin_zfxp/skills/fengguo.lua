
local fengguo = fk.CreateSkill {
  name = "heg__fengguo",
}

Fk:loadTranslationTable{
  ["heg__fengguo"] = "奉国",
  [":heg__fengguo"] = "准备阶段，你可以选择一名确定势力的角色，直到你下回合开始或死亡：其不可回复体力；若其存活，防止与其势力相同的其余角色受到的伤害。",

  ["#heg__fengguo-choose"] = "奉国：选择一名角色，其不可回复体力，其相同势力其余角色不可受到伤害",
  ["@@heg__fengguo"] = "奉国",
}

local H = require "packages.hegemony.util"

fengguo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengguo.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p)
        return p.kingdom ~= "unknown"
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p.kingdom ~= "unknown"
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#heg__fengguo-choose",
      skill_name = fengguo.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMarkIfNeed(to, "@@heg__fengguo", player)
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:removeTableMark(p, "@@heg__fengguo", player)
    end
  end,
}
fengguo:addEffect(fk.TurnStart, spec)
fengguo:addEffect(fk.Death, spec)

fengguo:addEffect(fk.PreHpRecover, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(target:getTableMark("@@heg__fengguo"), player)
  end,
  on_use = function(self, event, target, player, data)
    data:preventRecover()
  end,
})

fengguo:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.find(player.room:getOtherPlayers(target, false), function (p)
      return H.compareKingdomWith(target, p) and table.contains(p:getTableMark("@@heg__fengguo"), player)
    end)
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

return fengguo
