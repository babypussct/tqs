local pojun = fk.CreateSkill {
  name = "m_ex__pojun",
}

Fk:loadTranslationTable{
  ["m_ex__pojun"] = "破军",
  [":m_ex__pojun"] = "当你使用【杀】指定一个目标后，你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值），若如此做，"..
  "当前回合结束时，该角色获得这些牌；当你使用【杀】对手牌数与装备区里的牌数均不大于你的目标角色造成伤害时，此伤害+1。",

  ["#m_ex__pojun-invoke"] = "破军：是否扣置 %dest 的至多%arg张牌直到回合结束",
  ["$m_ex__pojun"] = "破军",

  ["$m_ex__pojun1"] = "犯大吴疆土者，盛必击而破之！",
  ["$m_ex__pojun2"] = "若敢来犯，必叫你大败而归！",
}

pojun:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pojun.name) and data.card.trueName == "slash" and
      not data.to.dead and data.to.hp > 0 and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = pojun.name,
      prompt = "#m_ex__pojun-invoke::" .. data.to.id .. ":" .. data.to.hp,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      target = data.to,
      flag = "he",
      skill_name = pojun.name,
      min = 1,
      max = data.to.hp
    })
    data.to:addToPile("$m_ex__pojun", cards, false, pojun.name, player)
  end,
})

pojun:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(pojun.name) and data.card and data.card.trueName == "slash" and
      data.by_user and
      player:getHandcardNum() >= data.to:getHandcardNum() and
      #player:getCardIds("e") >= #data.to:getCardIds("e")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

pojun:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and #player:getPile("$m_ex__pojun") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$m_ex__pojun"), Player.Hand, player, fk.ReasonPrey, pojun.name)
  end,
})

pojun:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
    return ai:getBenefitOfEvents(function(logic)
      logic:moveCardTo(table.random(target:getCardIds("he"), target.hp), Card.PlayerSpecial, target, fk.ReasonJustMove)
    end) >= 0
  end,
})

return pojun
