local konghun = fk.CreateSkill {
  name = "jiange__konghun",
}

Fk:loadTranslationTable{
  ["jiange__konghun"] = "控魂",
  [":jiange__konghun"] = "出牌阶段开始时，若你已损失体力值不小于敌方角色数，你可以对所有敌方角色各造成1点雷电伤害，然后你回复X点体力"..
  "（X为受到伤害的角色数）。",

  ["#jiange__konghun-invoke"] = "控魂：是否对所有敌方角色各造成1点雷电伤害，你回复体力？",
}

konghun:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(konghun.name) and player.phase == Player.Play and
      player:isWounded() and player:getLostHp() >= #player:getEnemies()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = konghun.name,
      prompt = "#jiange__konghun-invoke",
    }) then
      local tos = player:getEnemies()
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:isEnemy(player) and not p.dead then
        n = n + 1
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = konghun.name,
        }
      end
    end
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = n,
        recoverBy = player,
        skillName = konghun.name,
      }
    end
  end,
})

return konghun
