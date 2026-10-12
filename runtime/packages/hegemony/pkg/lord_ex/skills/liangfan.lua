local liangfan = fk.CreateSkill {
  name = "ld__liangfan",
}

Fk:loadTranslationTable {
  ["ld__liangfan"] = "量反",
  [":ld__liangfan"] = "准备阶段，若你的武将牌上有“函”，则你获得所有的“函”，然后失去1点体力。"..
  "当使用本回合获得的“函”造成伤害后，你可以获得受伤角色的一张牌。",

  ["@@ld__mengda_letter-turn"] = "函",
  ["#ld__liangfan-prey"] = "量反：你可以获得 %dest 一张牌",

  ["$ld__liangfan1"] = "今举兵投魏，必可封王拜相，一展宏图。",
  ["$ld__liangfan2"] = "今举义军事若成，吾为复汉元勋也。",
}


liangfan:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(liangfan.name) and player.phase == Player.Start and #player:getPile("ld__mengda_letter") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(player:getPile("ld__mengda_letter"), Card.PlayerHand, player, fk.ReasonJustMove, liangfan.name, nil, true, player,
      "@@ld__mengda_letter-turn")
    if not player.dead then
      room:loseHp(player, 1, liangfan.name)
    end
  end,
})

liangfan:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liangfan.name) and
      data.card and data.card:getMark("@@ld__mengda_letter-turn") > 0 and not data.to:isNude() and
      (data.to ~= player or #player:getCardIds("e") > 0)
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = liangfan.name,
      prompt = "#ld__liangfan-prey::"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = data.to == player and "e" or "he",
      skill_name = liangfan.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, liangfan.name, nil, false, player)
  end,
})

return liangfan
