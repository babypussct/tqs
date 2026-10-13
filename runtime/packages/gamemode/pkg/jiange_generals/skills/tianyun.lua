local tianyun = fk.CreateSkill {
  name = "jiange__tianyun",
}

Fk:loadTranslationTable{
  ["jiange__tianyun"] = "天陨",
  [":jiange__tianyun"] = "结束阶段，你可以失去1点体力，然后对一名敌方角色造成2点火焰伤害并弃置其装备区内所有牌。",

  ["#jiange__tianyun-invoke"] = "天陨：你可以失去1点体力，然后对一名敌方角色造成2点火焰伤害并弃置其装备区内所有牌",
  ["#jiange__tianyun-choose"] = "天陨：对一名敌方角色造成2点火焰伤害并弃置其装备区内所有牌",
}

tianyun:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tianyun.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tianyun.name,
      prompt = "#jiange__tianyun-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, tianyun.name)
    if player.dead or #player:getEnemies() == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = player:getEnemies(),
      min_num = 1,
      max_num = 1,
      prompt = "#jiange__tianyun-choose",
      skill_name = tianyun.name,
      cancelable = false,
    })[1]
    room:damage{
      from = player,
      to = to,
      damage = 2,
      damageType = fk.FireDamage,
      skillName = tianyun.name,
    }
    if not to.dead then
      to:throwAllCards("e", tianyun.name)
    end
  end,
})

return tianyun
