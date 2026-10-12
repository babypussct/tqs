local xunshi = fk.CreateSkill {
  name = "xunshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xunshi"] = "巡使",
  [":xunshi"] = "锁定技，你的多目标锦囊牌均视为无色【杀】。你使用无色牌无距离和次数限制且可以额外指定任意个目标，然后〖神裁〗的发动次数+1"..
  "（至多为5）。",

  ["#xunshi-choose"] = "巡使：你可以为此 %arg 额外指定任意个目标",

  ["$xunshi1"] = "秉身为正，辟易万邪！",
  ["$xunshi2"] = "巡御两界，路寻不平！",
}

xunshi:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunshi.name) and data.card.color == Card.NoColor
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill("shencai", true) and player:getMark(xunshi.name) < 4 then
      room:addPlayerMark(player, xunshi.name, 1)
    end
    local tos = data:getExtraTargets({ bypass_distances = true })
    if #tos > 0 then
      tos = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 9,
        prompt = "#xunshi-choose:::"..data.card:toLogString(),
        skill_name = xunshi.name,
        cancelable = true,
      })
      if #tos > 0 then
        data:addTarget(tos)
      end
    end
  end,
})

xunshi:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.color == Card.NoColor and player:hasSkill(xunshi.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

xunshi:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return player:hasSkill(xunshi.name) and card.multiple_targets and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", Card.NoSuit, card.number)
  end,
})

xunshi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and card:matchVSPattern(".|.|nocolor") and player:hasSkill(xunshi.name)
  end,
  bypass_distances =  function(self, player, skill, card)
    return card and card:matchVSPattern(".|.|nocolor") and player:hasSkill(xunshi.name)
  end,
})

return xunshi
