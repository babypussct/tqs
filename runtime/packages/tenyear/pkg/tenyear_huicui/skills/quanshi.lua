local quanshi = fk.CreateSkill {
  name = "quanshic",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["quanshic"] = "权势",
  [":quanshic"] = "转换技，你使用牌时可令此牌不可响应，"..
    "阳：摸此牌名字数张牌，若此牌未造成伤害，此技能本回合失效；"..
    "阴：弃此牌名字数张牌，若此牌造成伤害，此技能本回合失效。",

  [":quanshic_yang"] = "转换技，每回合限一次，你使用牌时可令此牌不可响应，"..
    "<font color=\"#E0DB2F\">阳：摸此牌名字数张牌，若此牌未造成伤害，此技能本回合失效；</font>"..
    "阴：弃此牌名字数张牌，若此牌造成伤害，此技能本回合失效。",
  [":quanshic_yin"] = "转换技，每回合限一次，你使用牌时可令此牌不可响应，"..
    "阳：摸此牌名字数张牌，若此牌未造成伤害，此技能本回合失效；"..
    "<font color=\"#E0DB2F\">阴：弃此牌名字数张牌，若此牌造成伤害，此技能本回合失效。</font>",

  ["#quanshic-yang"] = "权势：摸%arg2张牌令%arg无法响应，若未造成伤害，此技能本回合失效",
  ["#quanshic-yin"] = "权势：弃%arg2张牌令%arg无法响应，若造成伤害，此技能本回合失效",

  ["$quanshic1"] = "",
  ["$quanshic2"] = "",
}

quanshi:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quanshi.name) and
      --player:usedEffectTimes(quanshi.name, Player.HistoryTurn) < 1 and
      (player:getSwitchSkillState(quanshi.name, false) == fk.SwitchYang or
      #player:getCardIds("he") >= data.card:getNameLength())
  end,
  on_cost = function(self, event, target, player, data)
    local n = data.card:getNameLength()
    if player:getSwitchSkillState(quanshi.name, false) == fk.SwitchYang then
      return player.room:askToSkillInvoke(player, {
        skill_name = quanshi.name,
        prompt = "#quanshic-yang" .. ":::" .. data.card:toLogString() .. ":" .. tostring(n),
      })
    else
      local cards = player.room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = quanshi.name,
        prompt = "#quanshic-yin" .. ":::" .. data.card:toLogString() .. ":" .. tostring(n),
        cancelable = true,
        skip = true,
      })
      if #cards == n then
        event:setCostData(self, { cards = cards })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.players) do
      table.insertIfNeed(data.disresponsiveList, p)
    end
    local n = data.card:getNameLength()
    if player:currentSwitchState() == fk.SwitchYang then
      data.extra_data = data.extra_data or {}
      data.extra_data.quanshic_yang = player
      player:drawCards(n, quanshi.name)
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.quanshic_yin = player
      player.room:throwCard(event:getCostData(self).cards, quanshi.name, player, player)
    end
  end,
})

quanshi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(quanshi.name, true) and data.extra_data and
      ((data.extra_data.quanshic_yang == player and not data.damageDealt) or
      (data.extra_data.quanshic_yin == player and data.damageDealt))
  end,
  on_use = function(self, event, target, player, data)
    player.room:invalidateSkill(player, quanshi.name, "-turn")
  end,
})

return quanshi
