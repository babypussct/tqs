
local xicha = fk.CreateSkill {
  name = "xicha",
}

Fk:loadTranslationTable{
  ["xicha"] = "析察",
  [":xicha"] = "你受到1点伤害后，你可以观看伤害来源手牌，并秘密选择其中两张，若其下次使用牌为此牌，令该牌无效，你获得之。",

  ["#xicha-invoke"] = "析察：你可以观看 %dest 手牌并选择其中两张，若其下次使用牌为此牌，无效且你获得之",

  ["$xicha1"] = "用武则先威，用文则先德。",
  ["$xicha2"] = "治天下者，唯文与武。",
}

xicha:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xicha.name) and
      data.from and not data.from:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = xicha.name,
      prompt = "#xicha-invoke::"..data.from.id,
    }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      target = data.from,
      min = 2,
      max = 2,
      flag = { card_data = { { data.from.general, data.from:getCardIds("h") } } },
      skill_name = xicha.name,
    })
    local mark = player:getTableMark(xicha.name)
    mark[data.from] = mark[data.from] or {}
    table.insertTableIfNeed(mark[data.from], cards)
    room:setPlayerMark(player, xicha.name, mark)
  end,
})

xicha:addEffect(fk.CardUsing, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.extra_data and table.contains(data.extra_data.xicha or {}, player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    --data:removeAllTargets()
    --data.toCard = nil
    data:setNullified()
    if not player.dead and room:getCardArea(data.card) == Card.Processing then
      room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, xicha.name, nil, true, player)
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return player:getTableMark(xicha.name)[target]
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark(xicha.name)
    if table.contains(mark[target], data.card:getEffectiveId()) then
      data.extra_data = data.extra_data or {}
      data.extra_data.xicha = data.extra_data.xicha or {}
      table.insert(data.extra_data.xicha, player)
    end
    mark[target] = nil
    room:setPlayerMark(player, xicha.name, mark)
  end,
})

return xicha
