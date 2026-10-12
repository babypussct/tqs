local tongxins = fk.CreateSkill{
  name = "tongxins",
}

Fk:loadTranslationTable{
  ["tongxins"] = "恫心",
  [":tongxins"] = "每回合各限一次，当你造成或受到伤害后，你可以弃置受伤角色X+1张牌，对伤害来源造成1点伤害（X为受伤角色已损失体力值），"..
  "然后你获得弃置的【杀】，你使用这些【杀】无次数限制。",

  ["#tongxins-invoke"] = "恫心：你可以弃置 %dest %arg张牌，对 %src 造成1点伤害",
  ["@@tongxins-inhand"] = "恫心",

  ["$tongxins1"] = "三军胆裂非因剑，一念慑魂自威仪！",
  ["$tongxins2"] = "战鼓未擂心先乱，何不卸甲拜红妆？",
}

---@type TrigSkelSpec<DamageTrigFunc>
local spec = {
  anim_type = "offensive",
  max_turn_use_time = 1,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongxins.name) and data.from and
      #data.to:getCardIds("he") > 0 and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = tongxins.name,
      prompt = "#tongxins-invoke:"..data.from.id..":"..data.to.id..":"..(data.to:getLostHp() + 1),
    }) then
      event:setCostData(self, {tos = { data.to }})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.to:getLostHp() + 1
    local cards = room:askToChooseCards(player, {
      min = n,
      max = n,
      target = data.to,
      flag = "he",
      skill_name = tongxins.name,
    })
    room:throwCard(cards, tongxins.name, data.to, player)
    if data.from and not data.from.dead then
      room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = tongxins.name,
      }
    end
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return Fk:getCardById(id).trueName == "slash" and table.contains(room.discard_pile, id)
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, tongxins.name, nil, true, player, "@@tongxins-inhand")
    end
  end,
}

tongxins:addEffect(fk.Damage, spec, { check_effect_limit = true })
tongxins:addEffect(fk.Damaged, spec, { check_effect_limit = true })

tongxins:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@tongxins-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end,
})

tongxins:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and card:getMark("@@tongxins-inhand") > 0
  end,
})

return tongxins
