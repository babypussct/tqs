local lihuo = fk.CreateSkill {
  name = "os_ex__lihuo",
}

Fk:loadTranslationTable{
  ["os_ex__lihuo"] = "疠火",
  [":os_ex__lihuo"] = "当你使用普通【杀】时，你可以将此【杀】改为火【杀】，当此【杀】结算结束后，若此【杀】令其他角色进入过濒死状态，" ..
  "你失去1点体力。你使用火【杀】可以多选择一个目标。",

  ["#os_ex__lihuo-choose"] = "疠火：你可以为此%arg额外指定一个目标",

  ["$os_ex__lihuo1"] = "将士们，引火对敌！",
  ["$os_ex__lihuo2"] = "和我同归于尽吧！",
}

lihuo:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lihuo.name) and
      data.card.name == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk:cloneCard("fire__slash", data.card.suit, data.card.number)
    for k, v in pairs(data.card) do
      if card[k] == nil then
        card[k] = v
      end
    end
    if data.card:isVirtual() then
      card.subcards = data.card.subcards
    else
      card.id = data.card.id
    end
    card.skillNames = data.card.skillNames
    card.skillName = lihuo.name
    data.card = card
    data.extra_data = data.extra_data or {}
    data.extra_data.os_ex__lihuoUser = player.id
  end,
})

lihuo:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lihuo.name) and
      data.card.name == "fire__slash" and #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = 1,
      prompt = "#os_ex__lihuo-choose:::"..data.card:toLogString(),
      skill_name = lihuo.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

lihuo:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      player:isAlive() and
      (data.extra_data or {}).os_ex__lihuoUser == player.id and
      data.extra_data.os_ex__lihuoDying == true
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, lihuo.name)
  end,
})

lihuo:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    if target == player or not data.damage or not data.damage.card then
      return false
    end

    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and (parentUseData.data.extra_data or {}).os_ex__lihuoUser == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData then
      parentUseData.data.extra_data = parentUseData.data.extra_data or {}
      parentUseData.data.extra_data.os_ex__lihuoDying = true
    end
  end,
})

return lihuo
