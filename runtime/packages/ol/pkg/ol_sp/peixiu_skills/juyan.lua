local juyan = fk.CreateSkill {
  name = "peixiu_juyan",
}

Fk:loadTranslationTable {
  ["peixiu_juyan"] = "居延",
  [":peixiu_juyan"] = "你获得此技能后，从牌堆中获得三张攻击范围各不相同的武器牌。",
}

juyan:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(juyan.name) and data.skill.name == juyan.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local weapons, ranges = {}, {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)  ---@cast card Weapon
      if card.sub_type == Card.SubtypeWeapon then
        local range = card:getAttackRange()
        if not table.contains(ranges, range) then
          table.insert(ranges, range)
          table.insert(weapons, id)
          if #weapons == 3 then
            break
          end
        end
      end
    end
    room:moveCardTo(room:tableRandomPick(weapons, 3), Card.PlayerHand, player, fk.ReasonJustMove, juyan.name, nil, false, player)
  end
})

return juyan
