local midao = fk.CreateSkill {
  name = "ld__midao",
}

Fk:loadTranslationTable {
  ["ld__midao"] = "米道",
  [":ld__midao"] = "势力与你相同的角色于其出牌阶段内限一次，当其使用【杀】或伤害类锦囊牌指定目标时，其可以交给你一张手牌，"..
  "令你声明一种花色和一种属性，其此次使用牌的花色和造成伤害的属性改为你声明的花色和属性。",

  ["#ld__midao-invoke"] = "米道：你可以交给 %src 一张手牌，其改变你使用%arg的花色和伤害属性",
  ["#ld__midao-suit"] = "米道：声明一种花色，此%arg改为你声明的花色",
  ["#ld__midao-damageType"] = "米道：声明一种属性，此%arg造成的伤害改为你声明的属性",

  ["$ld__midao1"] = "恩结天地，法惠八荒。",
  ["$ld__midao2"] = "行五斗米道，可知暖饱。",
}

local H = require "packages.hegemony.util"

midao:addEffect(fk.TargetSpecifying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(midao.name) and data.firstTarget and
      H.compareKingdomWith(target, player) and target.phase == Player.Play and
      data.card.is_damage_card and not target:isKongcheng() and
      player:usedSkillTimes(midao.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = midao.name,
      cancelable = true,
      prompt = "#ld__midao-invoke:"..player.id.."::"..data.card:toLogString(),
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonGive, midao.name, nil, false, target)
    if player.dead then return end
    data.extra_data = data.extra_data or {}
    local choices = { "log_spade", "log_club", "log_heart", "log_diamond" }
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = midao.name,
      prompt = "#ld__midao-suit:::"..data.card:toLogString(),
    })
    local log = Fk:translate(choice)
    data.extra_data.ld__midao_suit = table.indexOf(choices, choice)
    choices = { "normal_damage", "fire_damage", "thunder_damage" }
    choice = room:askToChoice(player, {
      choices = choices,
      skill_name = midao.name,
      prompt = "#ld__midao-damageType:::"..data.card:toLogString(),
    })
    log = log .. "，" .. Fk:translate(choice)
    data.extra_data.ld__midao_damageType = table.indexOf(choices, choice)
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = log,
      toast = true,
    }
  end,
})

midao:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ld__midao_suit and
      data.extra_data.ld__midao_suit ~= data.card.suit
  end,
  on_refresh = function(self, event, target, player, data)
    data:changeCard(data.card.name, data.extra_data.ld__midao_suit)
  end,
})

midao:addEffect(fk.PreDamage, {
  can_refresh = function(self, event, target, player, data)
    if data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return end
      return use_event.data.extra_data and use_event.data.extra_data.ld__midao_damageType and
        data.damageType ~= use_event.data.extra_data.ld__midao_damageType
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not use_event then return end
    data.damageType = (use_event.data.extra_data or {}).ld__midao_damageType
  end,
})

return midao
