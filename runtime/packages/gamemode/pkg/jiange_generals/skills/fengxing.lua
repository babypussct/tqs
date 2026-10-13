local fengxing = fk.CreateSkill {
  name = "jiange__fengxing",
}

Fk:loadTranslationTable{
  ["jiange__fengxing"] = "风行",
  [":jiange__fengxing"] = "准备阶段，你可以视为对一名敌方角色使用一张【杀】。",

  ["#jiange__fengxing-slash"] = "风行：你可以视为对一名敌方角色使用【杀】",
}

fengxing:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengxing.name) and player.phase == Player.Start and
      table.find(player:getEnemies(), function (p)
        return not player:isProhibited(p, Fk:cloneCard("slash"))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = fengxing.name,
      prompt = "#jiange__fengxing-invoke",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        must_targets = table.map(player:getEnemies(), Util.IdMapper),
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("shensu")
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return fengxing
