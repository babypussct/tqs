local recast = fk.CreateSkill {
  name = "1v3_recast_weapon&",
}

Fk:loadTranslationTable{
  ["1v3_recast_weapon&"] = "武器重铸",
  [":1v3_recast_weapon&"] = "你可以重铸手里的武器牌。",

  ["#1v3_recast_weapon&"] = "你可以重铸手里的武器牌。",
}

recast:addEffect("active", {
  mute = true,
  prompt = "#1v3_recast_weapon&",
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon and
      table.contains(player:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, effect.from, recast.name)
  end,
})

return recast
