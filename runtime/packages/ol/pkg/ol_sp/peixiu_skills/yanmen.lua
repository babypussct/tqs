
local yanmen = fk.CreateSkill {
  name = "peixiu_yanmen",
}

Fk:loadTranslationTable {
  ["peixiu_yanmen"] = "雁门",
  [":peixiu_yanmen"] = "你获得此技能后，从牌堆中获得一张武器牌和一张进攻坐骑牌。",
}

yanmen:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yanmen.name) and data.skill.name == yanmen.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player.dead then return end

    local weapons = {}
    local off_horses = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.sub_type == Card.SubtypeWeapon then
        table.insert(weapons, id)
      elseif card.sub_type == Card.SubtypeOffensiveRide then
        table.insert(off_horses, id)
      end
    end

    local cards = {}
    if #weapons > 0 then
      local w = room:tableRandomPick(weapons, 1)
      table.insert(cards, w[1])
    end
    if #off_horses > 0 then
      local h = room:tableRandomPick(off_horses, 1)
      table.insert(cards, h[1])
    end

    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, yanmen.name, nil, false, player)
    end
  end
})

return yanmen
