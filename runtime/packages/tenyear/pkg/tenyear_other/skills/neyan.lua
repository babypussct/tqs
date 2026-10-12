local neyan = fk.CreateSkill {
  name = "neyan",
  tags = { Skill.Switch, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["neyan"] = "讷言",
  [":neyan"] = "转换技，锁定技，你使用非装备牌时，阳：需弃置一张同类型牌令此牌额外结算一次，否则此牌无效；阴：此牌无次数限制。",

  ["#neyan-discard"] = "讷言：请弃置一张%arg令此%arg2额外结算一次，否则此牌无效",
}

neyan:addEffect(fk.CardUsing, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(neyan.name) and data.card.type ~= Card.TypeEquip
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(neyan.name, true) == fk.SwitchYang then
      if #room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = neyan.name,
        pattern = ".|.|.|.|.|"..data.card:getTypeString(),
        prompt = "#neyan-discard:::"..data.card:getTypeString()..":"..data.card:toLogString(),
        cancelable = true,
      }) == 0 then
        --data:removeAllTargets()
        data:setNullified()
      else
        data.additionalEffect = (data.additionalEffect or 0) + 1
      end
    else
      if not data.extraUse then
        player:addCardUseHistory(data.card.trueName, -1)
        data.extraUse = true
      end
    end
  end,
})

neyan:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return player:hasSkill(neyan.name) and player:getSwitchSkillState(neyan.name) == fk.SwitchYin and card
  end,
})

return neyan
