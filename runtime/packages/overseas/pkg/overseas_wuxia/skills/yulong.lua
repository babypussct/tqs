local yulong = fk.CreateSkill {
  name = "os__yulong",
}

Fk:loadTranslationTable{
  ["os__yulong"] = "驭龙",
  [":os__yulong"] = "当你使用【杀】指定第一个目标后，你可以与其中一名目标拼点。若你此次拼点牌的颜色为：黑色，此【杀】伤害基数+1；红色，此【杀】不可被响应。" ..
  "然后若你：赢，则此【杀】不计入次数；没赢，你获得此【杀】。",

  ["#os__yulong-ask"] = "驭龙：你可以与一名目标拼点，根据你的拼点牌颜色执行效果，且赢则杀不计次数，没赢收回杀",

  ["$os__yulong1"] = "三尺青锋，为君驭六龙，定九州！",
  ["$os__yulong2"] = "十年砺剑，当率千军之众，堪万夫之雄！",
}

yulong:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(yulong.name) and
      data.firstTarget and
      data.card.trueName == "slash" and
      table.find(data.use.tos, function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = yulong.name
    local room = player.room
    local targets = table.filter(data.use.tos, function (p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__yulong-ask",
        skill_name = skillName,
        cancelable = true,
      }
    )
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({ to }, yulong.name)

    if pindian.fromCard.color == Card.Black then
      data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
    elseif pindian.fromCard.color == Card.Red then
      data.use.disresponsiveList = table.simpleClone(room.players)
    end
    if pindian.results[to].winner == player then
      if not data.use.extraUse then
        player:addCardUseHistory("slash", -1)
        data.use.extraUse = true
      end
    elseif room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(player, data.card, true, fk.ReasonPrey, player, yulong.name)
    end
  end,
})

yulong:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    if target == player and data.card and data.card.trueName == "slash" then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event and use_event.data.extra_data and use_event.data.extra_data.os__yulong == true then
        return not use_event.data.extraUse
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:addCardUseHistory("slash", -1)
    player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data.extraUse = true
  end,
})

return yulong
