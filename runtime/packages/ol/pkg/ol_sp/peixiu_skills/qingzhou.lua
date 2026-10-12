local qingzhou = fk.CreateSkill {
  name = "peixiu_qingzhou",
}

Fk:loadTranslationTable {
  ["peixiu_qingzhou"] = "青州",
  [":peixiu_qingzhou"] = "你获得此技能后，可以弃置所有手牌，然后摸等量的牌。",

  ["#peixiu_qingzhou-invoke"] = "青州：是否弃置所有手牌，然后摸等量的牌？",
}

qingzhou:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qingzhou.name) and
      data.skill.name == qingzhou.name and not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qingzhou.name,
      prompt = "#peixiu_qingzhou-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(cards, qingzhou.name, player, player)
      if not player.dead then
        player:drawCards(#cards, qingzhou.name)
      end
    end
  end
})

return qingzhou
