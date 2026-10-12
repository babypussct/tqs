local xiaoge = fk.CreateSkill {
  name = "xiaoge",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiaoge"] = "骁戈",
  [":xiaoge"] = "锁定技，你使用的【杀】：对因“飞径”成为额外目标的角色造成伤害时，防止之，然后你回复1点体力并获得其弃置的牌；"..
  "结算结束后，若仅指定了一名角色为目标，你视为对其使用一张【决斗】。",

  ["$xiaoge1"] = "有此骁勇将士，我何战不可得胜？",
  ["$xiaoge2"] = "此战收益颇丰，尔等皆有奖赏。",
  ["$xiaoge3"] = "小子，可能再与我战百八回合？",
  ["$xiaoge4"] = "我也不以多欺少，可敢与我单挑？",
}

xiaoge:addEffect(fk.DetermineDamageCaused, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(xiaoge.name) and data.card and data.card.trueName == "slash") then
      return false
    end

    local useEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not useEvent then
      return false
    end

    local useData = useEvent.data
    return useData.extra_data and (useData.extra_data.feijingExtra or {})[data.to]
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    ---@type string
    local skillName = xiaoge.name
    data:preventDamage()
    room:recover{
      who = player,
      num = 1,
      skillName = skillName,
      recoverBy = player,
    }

    local useEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not useEvent then
      return false
    end

    local useData = useEvent.data
    if useData.extra_data and (useData.extra_data.feijingExtra or {})[data.to] then
      local cardDiscard = useData.extra_data.feijingExtra[data.to]
      if room:getCardArea(cardDiscard) == Card.DiscardPile then
        room:obtainCard(player, cardDiscard, true, fk.ReasonPrey, player, skillName)
      end
    end
  end,
})

xiaoge:addEffect(fk.CardUseFinished, {
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      player:hasSkill(xiaoge.name) and
      #(data.tos or {}) > 0 and
      data:isOnlyTarget(data.tos[1]) and
      data.tos[1]:isAlive() and
      player:canUseTo(Fk:cloneCard("duel"), data.tos[1])
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("duel", nil, player, data.tos[1], xiaoge.name)
  end,
})

return xiaoge
