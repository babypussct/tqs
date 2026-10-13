local gongshen = fk.CreateSkill {
  name = "jiange__gongshen",
}

Fk:loadTranslationTable{
  ["jiange__gongshen"] = "工神",
  [":jiange__gongshen"] = "结束阶段，你可以令友方攻城器械各回复1点体力，或对敌方攻城器械各造成1点火焰伤害。",

  ["jiange__gongshen1"] = "友方攻城器械回复1点体力",
  ["jiange__gongshen2"] = "对敌方攻城器械造成1点火焰伤害",
}

gongshen:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gongshen.name) and player.phase == Player.Finish and
      (table.find(player:getEnemies(), function(p)
        return Fk.generals[p.general].jiange_machine
      end) or
      table.find(player:getFriends(), function(p)
        return Fk.generals[p.general].jiange_machine and p:isWounded()
      end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local friends = table.filter(player:getFriends(), function(p)
      return Fk.generals[p.general].jiange_machine and p:isWounded()
    end)
    if #friends > 0 then
      table.insert(choices, "jiange__gongshen1")
    end
    local enemies = table.filter(player:getEnemies(), function(p)
      return Fk.generals[p.general].jiange_machine
    end)
    if #enemies > 0 then
      table.insert(choices, "jiange__gongshen2")
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = gongshen.name,
      all_choices = {"jiange__gongshen1", "jiange__gongshen2", "Cancel"},
    })
    if choice ~= "Cancel" then
      local tos = choice == "jiange__gongshen1" and friends or enemies
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(gongshen.name)
    local tos = event:getCostData(self).tos
    if event:getCostData(self).choice == "jiange__gongshen1" then
      room:notifySkillInvoked(player, gongshen.name, "support")
      for _, p in ipairs(tos) do
        if not p.dead and p:isWounded() then
          room:recover{
            who = p,
            num = 1,
            recoverBy = player,
            skillName = gongshen.name,
          }
        end
      end
    else
      room:notifySkillInvoked(player, gongshen.name, "offensive")
      for _, p in ipairs(tos) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = gongshen.name,
          }
        end
      end
    end
  end,
})

return gongshen
