local jiuyuan = fk.CreateSkill {
  name = "peixiu_jiuyuan",
}

Fk:loadTranslationTable {
  ["peixiu_jiuyuan"] = "九原",
  [":peixiu_jiuyuan"] = "你使用【杀】可以额外指定任意名目标。",

  ["#peixiu_jiuyuan-choose"] = "九原：你可以为%arg额外指定任意个目标",
}

jiuyuan:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiuyuan.name) and
      data.card.trueName == "slash" and #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 20,
      targets = data:getExtraTargets(),
      skill_name = jiuyuan.name,
      prompt = "#peixiu_jiuyuan-choose:::" .. data.card:toLogString(),
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

return jiuyuan
