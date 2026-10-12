local daizui = fk.CreateSkill {
  name = "daizui",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["daizui"] = "戴罪",
  [":daizui"] = "限定技，当你受到致命伤害时，你可以防止此伤害，然后将对你造成伤害的牌置于伤害来源的武将牌上，称为“释”。" ..
  "本回合结束时，其获得其“释”。",

  ["daizui_shi"] = "释",

  ["$daizui1"] = "望丞相权且记过，容干将功折罪啊！",
  ["$daizui2"] = "干，谢丞相不杀之恩！",
}

daizui:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(daizui.name) and
      math.max(0, player.hp) + player.shield <= data.damage and
      player:usedSkillTimes(daizui.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    if data.card and data.from and data.from:isAlive() and room:getCardArea(data.card) == Card.Processing then
      data.from:addToPile("daizui_shi", data.card, true, daizui.name, player)
    end
  end,
})

daizui:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("daizui_shi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, player:getPile("daizui_shi"), true, fk.ReasonPrey, player, daizui.name)
  end,
})

return daizui
