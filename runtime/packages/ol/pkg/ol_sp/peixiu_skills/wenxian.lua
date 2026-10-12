local wenxian = fk.CreateSkill {
  name = "peixiu_wenxian",
}

Fk:loadTranslationTable {
  ["peixiu_wenxian"] = "温县",
  [":peixiu_wenxian"] = "你获得此技能后，加1点体力上限并回复1点体力，然后获得一张【虚妄之冕】。",
}

wenxian:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(wenxian.name) and data.skill.name == wenxian.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = wenxian.name,
    }
    if player.dead then return end
    local card = room:printCard("illusory_coronet", Card.Club, 4)
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, wenxian.name, nil, true, player)
  end
})

return wenxian
