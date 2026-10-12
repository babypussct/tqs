local taishan = fk.CreateSkill {
  name = "peixiu_taishan",
}

Fk:loadTranslationTable {
  ["peixiu_taishan"] = "泰山",
  [":peixiu_taishan"] = "获得此技能后，将一张【螭纹玉佩】置入手牌。",
}

taishan:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(taishan.name) and data.skill.name == taishan.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:printCard("hasshaku_keikogyoku", Card.Heart, 5)
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, taishan.name, nil, true, player)
  end
})

return taishan
