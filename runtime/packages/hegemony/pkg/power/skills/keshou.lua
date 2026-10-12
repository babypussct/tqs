local keshou = fk.CreateSkill{
  name = "ld__keshou",
}

Fk:loadTranslationTable{
  ["ld__keshou"] = "恪守",
  [":ld__keshou"] = "当你一次失去两张牌后，你可以令一名与你势力相同的角色下回合受到的伤害-1。",
  ["#ld__keshou"] = "恪守：你可以令一名与你势力相同的角色下回合受到的伤害-1",

  ["@ld__keshou"] = "恪守",
  ["@ld__keshou-turn"] = "恪守",

  ["$ld__keshou1"] = "仁以待民，自处不败之势。",
  ["$ld__keshou2"] = "宽济百姓，则得战前养备之机。",
}

local H = require "packages.hegemony.util"

keshou:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(keshou.name) then return false end
    local num = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or
              info.fromArea == Card.PlayerEquip then
            num = num + 1
          end
        end
      end
    end
    return num == 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(player, p)
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = keshou.name,
      prompt = "#ld__keshou",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:addPlayerMark(to, "@ld__keshou", 1)
  end,
})

keshou:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ld__keshou") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ld__keshou-turn", player:getMark("@ld__keshou"))
    room:setPlayerMark(player, "@ld__keshou", 0)
  end,
})

keshou:addEffect(fk.DamageInflicted, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@ld__keshou-turn") > 0 and data.damage > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(- player:getMark("@ld__keshou-turn"))
  end,
})

keshou:addEffect(fk.Deathed, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("@ld__keshou") > 0 or player:getMark("@ld__keshou-turn") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ld__keshou", 0)
    player.room:setPlayerMark(player, "@ld__keshou-turn", 0)
  end,
})

return keshou
