
local shifeng = fk.CreateSkill {
  name = "shifeng",
}

Fk:loadTranslationTable{
  ["shifeng"] = "试锋",
  [":shifeng"] = "每回合每项限一次，1.其他角色对你使用伤害牌结算后，你可以视为对其使用一张【决斗】；"..
    "2.其他角色使用【决斗】指定目标后，若目标不为你，你可以获得此牌并将目标更为你。",

  ["#shifeng-invoke1"] = "试锋：是否视为对 %dest 使用【决斗】？",
  ["#shifeng-invoke2"] = "试锋：是否将 %src 使用的%arg的目标转移给你？",

  ["$shifeng1"] = "阁下鞘藏山河，可否借某一观？",
  ["$shifeng2"] = "少年学剑，中年仗剑，而今白发，只求一败。",
}

shifeng:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  max_turn_use_time = 1,
  can_trigger = function(self, event, target, player, data)
    if data.card.is_damage_card and table.contains(data.tos, player) and data.from ~= player and not data.from.dead and
      player:hasSkill(shifeng.name) and self:withinTimesLimit(player) then
      local duel = Fk:cloneCard("duel")
      duel.skillName = shifeng.name
      return player:canUseTo(duel, data.from)
    end
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = shifeng.name,
      prompt = "#shifeng-invoke1::"..data.from.id
    }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local duel = Fk:cloneCard("duel")
    duel.skillName = shifeng.name
    player.room:useCard {
      from = player,
      tos = event:getCostData(self).tos,
      card = duel,
    }
  end,
})

--线上实测是在指定第一个目标后发动，取消其他目标并令data.to = player（会继承发动后的无双属性等）
--实现起来会有问题，故不采用
shifeng:addEffect(fk.TargetSpecifying, {
  anim_type = "control",
  max_turn_use_time = 1,
  can_trigger = function(self, event, target, player, data)
    return data.card.trueName == "duel" and data.firstTarget and
      data.from ~= player and not table.contains(data.use.tos, player) and
      player:hasSkill(shifeng.name) and self:withinTimesLimit(player) and
      not data.from:isProhibited(player, data.card)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = shifeng.name,
      prompt = "#shifeng-invoke2:"..data.from.id.."::"..data.card:toLogString()
    }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, shifeng.name)
    end
    data:cancelAllTarget()
    data:addTarget(player)
  end,
})

return shifeng
