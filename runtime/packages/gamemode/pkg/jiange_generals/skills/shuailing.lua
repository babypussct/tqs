local shuailing = fk.CreateSkill {
  name = "jiange__shuailing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__shuailing"] = "帅令",
  [":jiange__shuailing"] = "锁定技，友方角色摸牌阶段开始时，其进行一次判定，若结果为黑色，其获得判定牌。",
}

shuailing:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shuailing.name) and target.phase == Player.Draw and target:isFriend(player)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = target,
      reason = shuailing.name,
      pattern = ".|.|black",
    }
    room:judge(judge)
    if not target.dead and judge:matchPattern() and room:getCardArea(judge.card) == Card.DiscardPile then
      room:moveCardTo(judge.card, Card.PlayerHand, target, fk.ReasonJustMove, shuailing.name, nil, true, target)
    end
  end,
})

return shuailing
