
local junzhu = fk.CreateSkill{
  name = "junzhu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["junzhu"] = "菌煮",
  [":junzhu"] = "锁定技，准备阶段，你视为使用一张<a href=':amazing_mushroom'>【五菇丰登】</a>。只有懂的人能识别菌子效果。",

  ["$junzhu1"] = "治大国如烹小鲜，煮好一锅菌子比当个好君主难得多！",
  ["$junzhu2"] = "一场好雨刚歇，正是吃菌子的好季节！",
}

junzhu:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(junzhu.name) and
      #Fk:cloneCard("amazing_mushroom"):getAvailableTargets(player) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("amazing_mushroom")
    card.skillName = junzhu.name
    local targets = card:getDefaultTarget(player)
    room:sortByAction(targets)
    room:useVirtualCard("amazing_mushroom", nil, player, targets, junzhu.name)
  end,
})

return junzhu
