local shushen = fk.CreateSkill{
  name = "m_heg__shushen",
}

Fk:loadTranslationTable{
  ["m_heg__shushen"] = "淑慎",
  [":m_heg__shushen"] = "当你回复1点体力后，或一次失去大于X张牌后（X为你当前体力值），你可以令一名势力与你相同的其他角色摸一张牌。",

  ["#m_heg__shushen-choose"] = "淑慎：令一名势力相同的其他角色摸一张牌",

  ["$m_heg__shushen1"] = "船到桥头自然直。",
  ["$m_heg__shushen2"] = "妾身无恙，相公请安心征战。",
}

local H = require "packages.hegemony.util"

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return H.compareKingdomWith(player, p, false)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_heg__shushen-choose",
      skill_name = shushen.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, shushen.name)
  end,
}

shushen:addEffect(fk.HpRecover, {
  anim_type = "support",
  trigger_times = function (self, event, target, player, data)
    return data.num
  end,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shushen.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return H.compareKingdomWith(player, p, false)
      end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

shushen:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shushen.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return H.compareKingdomWith(player, p, false)
      end) then
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              n = n + 1
            end
          end
        end
      end
      return n > player.hp
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return shushen
