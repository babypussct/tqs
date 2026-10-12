local buqi = fk.CreateSkill {
  name = "buqi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["buqi"] = "不弃",
  [":buqi"] = "锁定技，一名角色进入濒死状态时，你移去两张“仁”，令其回复1点体力。当一名角色死亡后，你移去所有“仁”。",

  ["#buqi-invoke"] = "不弃：请移去两张“仁”，令 %dest 回复1点体力",

  ["$buqi1"] = "吾等既已纳其自托，宁可以急相弃邪？",
  ["$buqi2"] = "吾等既纳之，便不可怀弃人之心也。",
}

buqi:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(buqi.name) and #player:getPile("$huaxin_ren") > 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 2,
      max_num = 2,
      include_equip = false,
      skill_name = buqi.name,
      pattern = ".|.|.|$huaxin_ren",
      prompt = "#buqi-invoke::"..target.id,
      cancelable = true,
      expand_pile = "$huaxin_ren",
    })
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, buqi.name, nil, true, player)
    room:doIndicate(player, {target})
    if target:isWounded() and not target.dead then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = buqi.name,
      }
    end
  end,
})
buqi:addEffect(fk.Deathed, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(buqi.name) and #player:getPile("$huaxin_ren") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$huaxin_ren"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, buqi.name, nil, true, player)
  end,
})

return buqi
