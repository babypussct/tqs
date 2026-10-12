local chiyan = fk.CreateSkill {
  name = "changshi__chiyan",
}

Fk:loadTranslationTable{
  ["changshi__chiyan"] = "鸱咽",
  [":changshi__chiyan"] = "当你使用【杀】指定目标后，你可以将其一张牌扣置于其武将牌旁，该角色于本回合结束时获得此牌；当你使用【杀】对手牌数和"..
  "装备区内的牌数均不大于你的目标角色造成伤害时，此伤害+1。",

  ["#changshi__chiyan-invoke"] = "鸱咽：是否将 %dest 的一张牌置于其武将牌上直到回合结束？",
  ["$changshi__chiyan"] = "鸱咽",

  ["$changshi__chiyan1"] = "逆臣乱党，都要受这啄心之刑。",
}

chiyan:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(chiyan.name) and data.card.trueName == "slash" and
      not data.to:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = chiyan.name,
      prompt = "#changshi__chiyan-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      skill_name = chiyan.name,
      target = data.to,
      flag = "he",
    })
    data.to:addToPile("$changshi__chiyan", card, false, chiyan.name)
  end,
})
chiyan:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player:hasSkill(chiyan.name) and
      data.card and
      data.card.trueName == "slash" and
      data.by_user and
      player:getHandcardNum() >= data.to:getHandcardNum() and
      #player:getCardIds("e") >= #data.to:getCardIds("e")
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})
chiyan:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return #player:getPile("$changshi__chiyan") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:obtainCard(player, player:getPile("$changshi__chiyan"), false, fk.ReasonJustMove)
  end,
})

return chiyan
