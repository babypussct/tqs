local moqu = fk.CreateSkill {
  name = "moqu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["moqu"] = "魔躯",
  [":moqu"] = "锁定技，每名角色的回合结束时，若你的手牌数不大于体力值，你摸两张牌；当其他友方角色受到伤害后，你弃置一张牌。",
}

moqu:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(moqu.name) and player:getHandcardNum() <= player.hp
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, moqu.name)
  end,
})

moqu:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:hasSkill(moqu.name) and target:isFriend(player)
  end,
  on_use = function (self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = moqu.name,
      cancelable = false,
    })
  end,
})

return moqu
