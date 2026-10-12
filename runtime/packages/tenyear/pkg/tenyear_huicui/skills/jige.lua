
local jige = fk.CreateSkill {
  name = "jige",
}

Fk:loadTranslationTable{
  ["jige"] = "击格",
  [":jige"] = "你成为【杀】的目标时，可以打出一张点数比其大的【杀】抵消之；你对其他角色使用【杀】造成伤害时，可以弃置你与其手牌中所有的【杀】，"..
  "此牌伤害增加你比其多弃置的牌数。",

  ["#jige-ask"] = "击格：你可以打出一张点数大于%arg的【杀】，抵消此【杀】",
  ["#jige-discard"] = "击格：是否弃置你和 %dest 手牌中所有【杀】，令伤害增加你多弃置的牌数？",

  ["$jige1"] = "剑心如镜，剑气方可如虹！",
  ["$jige2"] = "剑之所向，万敌皆为刍狗！",
}

jige:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jige.name) and
      data.card.trueName == "slash" and data.card.number > 0 and data.card.number < 13 and
      #player:getHandlyIds() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getHandlyIds(), function (id)
      return Fk:getCardById(id).trueName == "slash" and Fk:getCardById(id).number > data.card.number and
        not player:prohibitResponse(Fk:getCardById(id))
    end)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = jige.name,
      pattern = tostring( Exppattern{ id = ids } ),
      include_equip = true,
      prompt = "#jige-ask:::"..data.card.number,
      cancelable = true,
      expand_pile = table.filter(ids, function (id)
        return not table.contains(player:getCardIds("he"), id)
      end),
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:responseCard({
      responseToEvent = nil,
      from = player,
      card = Fk:getCardById(event:getCostData(self).cards[1]),
    })
    data.extra_data = data.extra_data or {}
    data.extra_data.jige = data.extra_data.jige or {}
    table.insertIfNeed(data.extra_data.jige, player)
  end,
})

jige:addEffect(fk.PreCardEffect, {
  can_refresh = function (self, event, target, player, data)
    return data.to == player and data.extra_data and table.contains(data.extra_data.jige or {}, player)
  end,
  on_refresh =function (self, event, target, player, data)
    data.isCancellOut = true
  end,
})

jige:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jige.name) and
      data.card and data.card.trueName == "slash" and
      not (player:isKongcheng() and data.to:isKongcheng())
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jige.name,
      prompt = "#jige-discard::"..data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards1 = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).trueName == "slash" and not player:prohibitDiscard(id)
    end)
    room:throwCard(cards1, jige.name, player, player)
    local cards2 = table.filter(data.to:getCardIds("h"), function (id)
      return Fk:getCardById(id).trueName == "slash" and not data.to:prohibitDiscard(id)
    end)
    room:throwCard(cards2, jige.name, data.to, player)
    if #cards1 > #cards2 then
      data:changeDamage(#cards1 - #cards2)
    end
  end,
})

return jige
