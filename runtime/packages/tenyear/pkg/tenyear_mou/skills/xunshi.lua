local xunshi = fk.CreateSkill {
  name = "xunshiz",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xunshiz"] = "迅矢",
  [":xunshiz"] = "锁定技，你使用雷【杀】无距离和次数限制；当你使用雷【杀】对一名角色造成伤害后，其随机弃置一张牌，你摸两张牌。",

  ["$xunshiz1"] = "红缨缚的卢，飞矢毙雏凤！",
  ["$xunshiz2"] = "今日，当效马陵旧事，毙敌于秘径！",
}

--连环伤害也能发动，未弃牌也能摸牌
xunshi:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunshi.name) and data.card and data.card.name == "thunder__slash"
  end,
  on_use = function(self, event, target, player, data)
    local to = data.to
    if not to.dead then
      local cards = table.filter(to:getCardIds("h"), function(id)
        return not to:prohibitDiscard(id)
      end)
      if #cards > 0 then
        local room = player.room
        room:throwCard(room:tableRandomPick(cards, 1), xunshi.name, to, to)
      end
    end
    if not player.dead then
      player:drawCards(2, xunshi.name)
    end
  end,
})

xunshi:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.name == "thunder__slash" and player:hasSkill(xunshi.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

xunshi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and card.name == "thunder__slash" and player:hasSkill(xunshi.name)
  end,
  bypass_distances =  function(self, player, skill, card)
    return card and card.name == "thunder__slash" and player:hasSkill(xunshi.name)
  end,
})

return xunshi
