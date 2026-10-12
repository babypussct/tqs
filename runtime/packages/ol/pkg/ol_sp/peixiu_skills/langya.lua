local langya = fk.CreateSkill {
  name = "peixiu_langya",
}

Fk:loadTranslationTable {
  ["peixiu_langya"] = "琅琊",
  [":peixiu_langya"] = "你获得此技能后，观看牌堆顶的五张牌，然后以任意顺序置于牌堆顶或牌堆底。",
}

langya:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(langya.name) and data.skill.name == langya.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:askToGuanxing(player, { cards = room:getNCards(5) })
  end
})

return langya
