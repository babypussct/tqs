
local liangfan = fk.CreateSkill {
  name = "ld__liangfan",
}

Fk:loadTranslationTable {
  ["ld__liangfan"] = "量反",
  [":ld__liangfan"] = "准备阶段，你可以使用“函”，对目标造成伤害后你可以获得其一张牌；结算后若未造成伤害，你失去1点体力。",

  ["#ld__liangfan-use"] = "量反：你可以使用“函”，造成伤害后可以获得目标一张牌，若未造成伤害则失去1点体力",
  ["#ld__liangfan-prey"] = "量反：你可以获得 %dest 一张牌",

  ["$ld__liangfan1"] = "今举兵投魏，必可封王拜相，一展宏图。",
  ["$ld__liangfan2"] = "今举义军事若成，吾为复汉元勋也。",
}


liangfan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liangfan.name) and player.phase == Player.Start and
      #player:getPile("ld__mengda_letter") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseRealCard(player, {
      pattern = player:getPile("ld__mengda_letter"),
      skill_name = liangfan.name,
      prompt = "#ld__liangfan-use",
      extra_data = {
        bypass_times = true,
        expand_pile = player:getPile("ld__mengda_letter"),
        extraUse = true,
      },
      cancelable = true,
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).extra_data
    use.extra_data = use.extra_data or {}
    use.extra_data.ld__liangfan = player
    room:useCard(use)
    if not player.dead and not use.damageDealt then
      room:loseHp(player, 1, liangfan.name)
    end
  end,
})

liangfan:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(liangfan.name) and
      data.card and not data.to:isNude() and (data.to ~= player or #player:getCardIds("e") > 0) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        return (use_event.data.extra_data or {}).ld__liangfan == player
      end
    end
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
