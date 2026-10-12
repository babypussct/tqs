local cuijin = fk.CreateSkill {
  name = "cuijin",
}

Fk:loadTranslationTable{
  ["cuijin"] = "催进",
  [":cuijin"] = "当你或攻击范围内的角色使用【杀】时，你可以弃置一张牌，令此【杀】伤害基数+1。"..
  "当此【杀】结算结束后，若未造成伤害，你摸一张牌并对使用者造成1点伤害。",

  ["#cuijin-ask"] = "催进：是否弃置一张牌，令 %dest 使用的%arg伤害+1？若未造成伤害，你摸一张牌并对 %dest 造成1点伤害。",

  ["$cuijin1"] = "诸军速行，违者军法论处！",
  ["$cuijin2"] = "快！贻误军机者，定斩不赦！",
}

cuijin:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(cuijin.name) and
      data.card.trueName == "slash" and
      (target == player or player:inMyAttackRange(target)) and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = cuijin.name,
        cancelable = true,
        prompt = "#cuijin-ask::" .. target.id .. ":" .. data.card:toLogString(),
        skip = true,
      }
    )
    if #card > 0 then
      event:setCostData(self, { tos = { target }, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, cuijin.name, player, player)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.mobileCuijin = data.extra_data.mobileCuijin or {}
    table.insert(data.extra_data.mobileCuijin, player)
  end,
})

cuijin:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      not data.damageDealt and
      data.extra_data and
      data.extra_data.mobileCuijin and
      table.contains(data.extra_data.mobileCuijin, player) and
      player:isAlive()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, cuijin.name)
    if target:isAlive() then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = cuijin.name,
      }
    end
  end,
})

return cuijin
