local wuwei = fk.CreateSkill {
  name = "peixiu_wuwei",
}

Fk:loadTranslationTable {
  ["peixiu_wuwei"] = "武威",
  [":peixiu_wuwei"] = "你使用伤害牌可以额外指定一个目标（每回合限一次）。",

  ["#peixiu_wuwei-choose"] = "武威：你可以为%arg增加一个目标",
}

wuwei:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.is_damage_card and
      player:usedSkillTimes(wuwei.name, Player.HistoryTurn) == 0 and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = 1,
      prompt = "#peixiu_wuwei-choose:::" .. data.card:toLogString(),
      skill_name = wuwei.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    data:addTarget(to)
  end,
})

return wuwei
