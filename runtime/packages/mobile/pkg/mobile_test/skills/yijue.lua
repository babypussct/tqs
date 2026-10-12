local yijue = fk.CreateSkill({
  name = "m_yuan__yijue",
  tags = { Skill.Compulsory },
})

Fk:loadTranslationTable{
  ["m_yuan__yijue"] = "义绝",
  [":m_yuan__yijue"] = "锁定技，你对一名角色造成致命伤害时，其选择是否交给你任意张牌，然后你选择一项：" ..
  "1.本回合其不能使用或打出牌，你弃置所有与这些牌花色相同的手牌；2.防止此伤害，本轮其与你使用牌指定对方为目标时，取消之。",

  ["#m_yuan__yijue-give"] = "义绝：你可以交给 %src 任意张牌，其选择一项",
  ["m_yuan__yijue_discard"] = "本回合其不能使用打出牌，你弃置这些花色的手牌",
  ["m_yuan__yijue_prevent"] = "防止此伤害，本轮相互使用牌指定目标时取消之",
  ["@@m_yuan__yijue-turn"] = "义绝 禁止用牌",

  ["$m_yuan__yijue1"] = "财帛不足以动吾心，爵禄不足以移吾志！",
  ["$m_yuan__yijue2"] = "身外之物，岂及兄弟手足之情？",
  ["$m_yuan__yijue3"] = "今日放公一命，以报昔日之恩。",
  ["$m_yuan__yijue4"] = "吾读春秋，岂不知大义所在？",
}

yijue:addEffect(fk.DetermineDamageCaused, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yijue.name) and
      player ~= data.to and not data.to.dead and
      data.damage >= math.max(0, data.to.hp) + data.to.shield
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(data.to, {
      min_num = 1,
      max_num = data.to:getHandcardNum(),
      include_equip = true,
      skill_name = yijue.name,
      prompt = "#m_yuan__yijue-give:"..player.id,
      cancelable = true,
    })
    local suits = {}
    if #cards > 0 then
      for _, id in ipairs(cards) do
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
      table.removeOne(suits, Card.NoSuit)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, yijue.name, nil, false, data.to)
      if player.dead then return end
    end
    local choice = room:askToChoice(player, {
      choices = { "m_yuan__yijue_discard", "m_yuan__yijue_prevent" },
      skill_name = yijue.name,
    })
    if choice == "m_yuan__yijue_discard" then
      if not data.to.dead then
        room:setPlayerMark(data.to, "@@m_yuan__yijue-turn", 1)
      end
      cards = table.filter(player:getCardIds("h"), function (id)
        return table.contains(suits, Fk:getCardById(id).suit)
      end)
      room:throwCard(cards, yijue.name, player, player)
    else
      data:preventDamage()
      room:addTableMarkIfNeed(player, "m_yuan__yijue-round", data.to)
      if not data.to.dead then
        room:addTableMarkIfNeed(data.to, "m_yuan__yijue-round", player)
      end
    end
  end,
})

yijue:addEffect(fk.TargetSpecifying, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("m_yuan__yijue-round"), data.to) and not data.cancelled
  end,
  on_use = function(self, event, target, player, data)
    data:cancelCurrentTarget()
  end,
})

yijue:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    return player:getMark("@@m_yuan__yijue-turn") > 0 and card
  end,
  prohibit_response = function (self, player, card)
    return player:getMark("@@m_yuan__yijue-turn") > 0 and card
  end,
})

return yijue
