local benlei = fk.CreateSkill {
  name = "jiange__benlei",
}

Fk:loadTranslationTable{
  ["jiange__benlei"] = "奔雷",
  [":jiange__benlei"] = "准备阶段，你可以对一名敌方攻城器械造成2点雷电伤害。",

  ["#jiange__benlei-choose"] = "奔雷：你可以对一名敌方攻城器械造成2点雷电伤害",
}

benlei:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benlei.name) and player.phase == Player.Start and
      table.find(player:getEnemies(), function (p)
        return Fk.generals[p.general].jiange_machine
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getEnemies(), function (p)
      return Fk.generals[p.general].jiange_machine
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#jiange__benlei-choose",
      skill_name = benlei.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage({
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 2,
      damageType = fk.ThunderDamage,
      skillName = benlei.name,
    })
  end,
})

return benlei
