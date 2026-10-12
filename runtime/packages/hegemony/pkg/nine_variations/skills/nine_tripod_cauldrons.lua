
local skill = fk.CreateSkill{
  name = "#nine_tripod_cauldrons_skill",
  tags = { Skill.Compulsory },
  attached_equip = "nine_tripod_cauldrons",
}

local H = require "packages.hegemony.util"

---@param player ServerPlayer
local hegInstantWin = function(player)
  local room = player.room
  local kingdom = H.getKingdom(player)
  local alive = table.filter(room.alive_players, function(p)
    return H.getKingdom(p) == kingdom
  end)
  room:gameOver(alive)
end

skill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and H.getKingdom(player) ~= "unknown" then
      for _, move in ipairs(data) do
        if move.to == player or move.from == player then
          return true
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    if #table.filter(player:getEquipCards(), function (card)
      return card.package.name == "nine_variations"
    end) >= 4 then
      hegInstantWin(player)
    end
  end,
})

skill:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      #table.filter(player:getEquipCards(), function (card)
        return card.package.name == "nine_variations"
      end) >= 4
  end,
  on_trigger = function (self, event, target, player, data)
    hegInstantWin(player)
  end,
})

return skill
