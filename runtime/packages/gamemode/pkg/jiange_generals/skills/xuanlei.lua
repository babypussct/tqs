local xuanlei = fk.CreateSkill {
  name = "jiange__xuanlei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__xuanlei"] = "玄雷",
  [":jiange__xuanlei"] = "锁定技，准备阶段，你对判定区内有牌的所有敌方角色各造成1点雷电伤害。",
}

xuanlei:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanlei.name) and player.phase == Player.Start and
      table.find(player:getEnemies(), function (p)
        return #p:getCardIds("j") > 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local tos = table.filter(player:getEnemies(), function (p)
      return #p:getCardIds("j") > 0
    end)
    player.room:sortByAction(tos)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getEnemies(), function (p)
      return #p:getCardIds("j") > 0
    end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = xuanlei.name,
        }
      end
    end
  end,
})

return xuanlei
