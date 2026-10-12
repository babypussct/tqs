local beiping = fk.CreateSkill {
  name = "peixiu_beiping",
}

Fk:loadTranslationTable {
  ["peixiu_beiping"] = "北平",
  [":peixiu_beiping"] = "你获得此技能后，从牌堆中获得两张【杀】。",
}

beiping:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(beiping.name) and data.skill.name == beiping.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("slash", 2)
    if #cards > 0 then
      room:obtainCard(player, cards, true, fk.ReasonJustMove, player, beiping.name)
    end
  end
})

return beiping
