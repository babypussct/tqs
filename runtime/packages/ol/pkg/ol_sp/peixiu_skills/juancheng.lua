local juancheng = fk.CreateSkill {
  name = "peixiu_juancheng",
}

Fk:loadTranslationTable {
  ["peixiu_juancheng"] = "鄄城",
  [":peixiu_juancheng"] = "你获得此技能后，判定，若为黑色，你获得判定牌并重复此流程。",
}

juancheng:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(juancheng.name) and data.skill.name == juancheng.name
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    while true do
      local judge = {
        who = player,
        reason = juancheng.name,
        pattern = ".|.|black",
      }
      room:judge(judge)
      if not judge:matchPattern() or player.dead then
        break
      end
    end
  end
})

juancheng:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == juancheng.name and
      data.card.color == Card.Black and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, nil, player, juancheng.name)
  end,
})

return juancheng
