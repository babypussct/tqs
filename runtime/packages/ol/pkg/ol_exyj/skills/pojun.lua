local pojun = fk.CreateSkill {
  name = "ol_ex__pojun",
}

Fk:loadTranslationTable{
  ["ol_ex__pojun"] = "破军",
  [":ol_ex__pojun"] = "当你使用【杀】指定一个目标后，你可以将其至多X张牌移出游戏直到当前回合结束（X为其体力值）。"..
  "你使用的【杀】对手牌数与装备区牌数均不大于你的角色造成的伤害+1。",

  ["#ol_ex__pojun-invoke"] = "破军：是否扣置%dest的至多%arg张牌直到回合结束",
  ["$ol_ex__pojun"] = "破军",

  ["$ol_ex__pojun1"] = "吾尚未尽全力，敌已亡命丧胆！",
  ["$ol_ex__pojun2"] = "知我在此，安敢来犯！",
}

pojun:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pojun.name) and data.card.trueName == "slash" and
      not data.to.dead and data.to.hp > 0 and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = pojun.name,
      prompt = "#ol_ex__pojun-invoke::" .. data.to.id .. ":" .. data.to.hp,
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
    data.to:addToPile("$ol_ex__pojun", cards, false, self.name, player.id)
  end,
})

pojun:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(pojun.name) and
      data.card and data.card.trueName == "slash" and
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
    return not player.dead and #player:getPile("$ol_ex__pojun") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$ol_ex__pojun"), Player.Hand, player, fk.ReasonJustMove, pojun.name)
  end,
})

return pojun
