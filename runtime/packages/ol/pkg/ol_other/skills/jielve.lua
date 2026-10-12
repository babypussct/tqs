local jielve = fk.CreateSkill{
  name = "ol_fd__jielve",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_fd__jielve"] = "劫掠",
  [":ol_fd__jielve"] = "锁定技，当你对其他角色造成伤害后，你获得其每个区域内各一张牌，然后你失去1点体力。",

  ["$ol_fd__jielve1"] = "劫命掠财，毫不费力。",
  ["$ol_fd__jielve2"] = "人财，皆掠之，哈哈！",
}

local U = require "packages.utility.utility"

jielve:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jielve.name) and
      data.to ~= player and not data.to.dead and not data.to:isAllNude()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.to}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = U.askforCardsChosenFromAreas(player, data.to, "hej", jielve.name, nil, nil, false)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, jielve.name, nil, false, player)
    if not player.dead then
      room:loseHp(player, 1, jielve.name)
    end
  end,
})

return jielve
