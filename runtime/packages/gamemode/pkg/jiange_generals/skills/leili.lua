local leili = fk.CreateSkill {
  name = "jiange__leili",
}

Fk:loadTranslationTable{
  ["jiange__leili"] = "雷厉",
  [":jiange__leili"] = "当你使用【杀】造成伤害后，你可以对另一名敌方角色造成1点雷电伤害。",

  ["#jiange__leili-choose"] = "雷厉：你可以对另一名敌方角色造成1点雷电伤害",
}

leili:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(leili.name) and data.card and data.card.trueName == "slash" and
      table.find(player:getEnemies(), function (p)
        return p ~= data.to
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getEnemies(), function (p)
      return p ~= data.to
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#jiange__leili-choose",
      skill_name = leili.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ol_ex__shensu")
    room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = leili.name,
    }
  end,
})

return leili
