local yiju = fk.CreateSkill {
  name = "yiju",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yiju"] = "义拒",
  [":yiju"] = "锁定技，其他角色使用牌指定你为唯一目标后，你弃置一张牌。",

  ["$yiju1"] = "公欲以子之腐鼠而饲我邪？",
  ["$yiju2"] = "绢帛染了脂血，恐污了清白。",
}

yiju:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yiju.name) and
      data.from ~= player and data:isOnlyTarget(player) and not player:isNude()
  end,
  on_use = function (self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = yiju.name,
      cancelable = false,
    })
  end,
})

return yiju
