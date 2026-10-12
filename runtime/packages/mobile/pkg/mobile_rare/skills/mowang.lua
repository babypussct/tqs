local mowang = fk.CreateSkill {
  name = "mowang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mowang"] = "殁亡",
  [":mowang"] = "锁定技，当你即将死亡时，若你拥有技能〖党锢〗且你仍有未亮出的“常侍”牌，则改为休整一轮；回合结束时，你死亡。",
}

mowang:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(mowang.name)
  end,
  on_use = function (self, event, target, player, data)
    player.room:killPlayer{
      who = player,
    }
  end,
})
mowang:addEffect(fk.BeforeGameOverJudge, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(mowang.name, false, true) and
      player:hasSkill("danggu", true, true) and
      type(player.tag["changshi_cards"]) == "table" and
      #player.tag["changshi_cards"] > 0 and
      player.maxHp > 0
  end,
  on_use = function (self, event, target, player, data)
    player._splayer:setDied(false)
    player.room:setPlayerRest(player, 1)
  end,
})

return mowang
