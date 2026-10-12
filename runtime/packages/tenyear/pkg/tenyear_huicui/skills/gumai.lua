local gumai = fk.CreateSkill {
  name = "gumai",
}

Fk:loadTranslationTable{
  ["gumai"] = "孤脉",
  [":gumai"] = "每轮限一次，当你造成/受到伤害时，你可以展示所有手牌，令此伤害+1/-1。若展示的牌花色均相同，你可以弃置一张手牌"..
  "令此技能视为未发动过。",

  ["#gumai-plus"] = "孤脉：你可以展示手牌，令 %dest 受到的%arg点%arg2伤害+1",
  ["#gumai-minus"] = "孤脉：你可以展示手牌，令 %dest 受到的%arg点%arg2伤害-1",

  ["#gumai-discard"] = "孤脉：是否弃置一张手牌令此技能视为未发动？",

  ["$gumai1"] = "松柏入青云，野菊守霜晨。",
  ["$gumai2"] = "兄别之言在耳，不敢使田亩荒芜。",
}

local spec = { ---@type TrigSkelSpec<fun(self: TriggerSkill, event: DamageEvent, target: ServerPlayer, player: ServerPlayer, data: DamageData):any>
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gumai.name) and not player:isKongcheng() and
      player:usedSkillTimes(gumai.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local plus = event == fk.DamageCaused
    local invoke = player.room:askToSkillInvoke(player, {
      skill_name = gumai.name,
      prompt = (plus and "#gumai-plus::" or "#gumai-minus::") .. data.to.id .. ":" .. data.damage .. ":" .. Fk:getDamageNatureName(data.damageType),
    })
    if invoke then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:changeDamage(event == fk.DamageCaused and 1 or -1)
    local cards = table.simpleClone(player:getCardIds("h"))
    local first_card = Fk:getCardById(cards[1])
    local yes = table.every(cards, function (id)
      return Fk:getCardById(id):compareSuitWith(first_card)
    end)
    player:showCards(cards)
    if player.dead then return end
    if yes and
      #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = gumai.name,
      cancelable = true,
      prompt = "#gumai-discard",
    }) == 1 then
      player:setSkillUseHistory(gumai.name, 0, Player.HistoryRound)
    end
  end,
}

gumai:addEffect(fk.DamageCaused, spec)
gumai:addEffect(fk.DamageInflicted, spec)

return gumai
