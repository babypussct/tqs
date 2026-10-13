local tunshi = fk.CreateSkill {
  name = "jiange__tunshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__tunshi"] = "吞噬",
  [":jiange__tunshi"] = "锁定技，准备阶段，你对所有手牌数大于你的敌方角色各造成1点伤害。",
}

tunshi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tunshi.name) and player.phase == Player.Start and
      table.find(player:getEnemies(), function (p)
        return p:getHandcardNum() > player:getHandcardNum()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player:getEnemies(), function (p)
      return p:getHandcardNum() > player:getHandcardNum()
    end)
    player.room:sortByAction(targets)
    event:setCostData(self, {tos = targets})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getEnemies(), function (p)
      return p:getHandcardNum() > player:getHandcardNum()
    end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage({
          from = player,
          to = p,
          damage = 1,
          skill_name = tunshi.name,
        })
      end
    end
  end,
})

return tunshi
