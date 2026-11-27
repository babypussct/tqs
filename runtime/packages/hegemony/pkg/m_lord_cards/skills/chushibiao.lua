
local skill = fk.CreateSkill{
  name = "#chushibiao_skill",
  attached_equip = "chushibiao",
}

skill:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Start
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick")
    if #cards > 0 then
      room:moveCardTo(room:tableRandomPick(cards), Card.PlayerHand, player, fk.ReasonJustMove, skill.name, nil, false, player)
    end
  end,
})

return skill
