local xunji = fk.CreateSkill{
  name = "heg__xunjim",
}

Fk:loadTranslationTable{
  ["heg__xunjim"] = "勋济",
  [":heg__xunjim"] = "你使用【杀】可以多选择至多两名角色为目标，此【杀】结算结束后，若对所有目标角色均造成伤害，此【杀】不计次数。",

  ["#heg__xunjim-choose"] = "勋济：你可以为此%arg额外指定至多两个目标",

  ["$heg__xunjim1"] = "天统之境，岂容丑虏犯边。",
  ["$heg__xunjim2"] = "凉州有危，臣者当济。",
}

xunji:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunji.name) and data.card.trueName == "slash" and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 2,
      targets = data:getExtraTargets(),
      skill_name = xunji.name,
      prompt = "#heg__xunjim-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
    if not data.extraUse then
      data.extra_data = data.extra_data or {}
      data.extra_data.heg__xunjim = true
    end
  end,
})

xunji:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      data.extra_data and data.extra_data.heg__xunjim and data.damageDealt and
      table.every(data.tos, function (p)
        return data.damageDealt[p] and data.damageDealt[p] > 0
      end) and
      not data.extraUse
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
    player:addCardUseHistory("slash", -1)
  end,
})

return xunji
