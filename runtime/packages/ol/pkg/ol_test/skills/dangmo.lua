
local dangmo = fk.CreateSkill {
  name = "ol__dangmo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__dangmo"] = "荡魔",
  [":ol__dangmo"] = "锁定技，当你使用仅指定单一目标的伤害牌时，选择一项：1.令此牌额外结算一次；2.令此牌目标数+1。",

  ["#ol__dangmo-choose"] = "荡魔：为此%arg额外指定一个目标，或点“取消”额外结算一次",

  ["$ol__dangmo1"] = "",
  ["$ol__dangmo2"] = "",
}

dangmo:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangmo.name) and
      data.card.is_damage_card and #data.tos == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #data:getExtraTargets() > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = data:getExtraTargets(),
        min_num = 1,
        max_num = 1,
        prompt = "#ol__dangmo-choose:::"..data.card:toLogString(),
        skill_name = dangmo.name,
      })
      if #to > 0 then
        data:addTarget(to[1])
        return
      end
    end
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

return dangmo
