local bushi = fk.CreateSkill {
  name = "ld__bushi",
}

Fk:loadTranslationTable {
  ["ld__bushi"] = "布施",
  [":ld__bushi"] = "当你受到1点伤害后，你可以令势力与你相同的一名角色摸一张牌；当你对其他角色造成伤害后，你令势力与其相同的一名角色摸一张牌。",

  ["#ld__bushi-invoke"] = "布施：令一名角色摸一张牌",

  ["$ld__bushi1"] = "争斗，永远没有赢家。",
  ["$ld__bushi2"] = "和平，永远没有输家。",
}

local H = require "packages.hegemony.util"

bushi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return H.compareExpectedKingdomWith(player, p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = bushi.name,
      prompt = "#ld__bushi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, bushi.name)
  end,
})

bushi:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(bushi.name) and data.to ~= player and
      table.find(player.room.alive_players, function (p)
        return H.compareKingdomWith(data.to, p)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return H.compareKingdomWith(data.to, p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = bushi.name,
      prompt = "#ld__bushi-choose",
      cancelable = false,
    })[1]
    to:drawCards(1, bushi.name)
  end,
})

return bushi
