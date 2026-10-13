local huodi = fk.CreateSkill {
  name = "jiange__huodi",
}

Fk:loadTranslationTable{
  ["jiange__huodi"] = "惑敌",
  [":jiange__huodi"] = "结束阶段，若有友方角色武将牌背面朝上，你可以令一名敌方角色翻面。",

  ["#jiange__huodi-choose"] = "惑敌：你可以令一名敌方角色翻面",
}

huodi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huodi.name) and player.phase == Player.Finish and
      table.find(player:getFriends(), function (p)
        return not p.faceup
      end) and
      #player:getEnemies() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = player:getEnemies(),
      min_num = 1,
      max_num = 1,
      prompt = "#jiange__huodi-choose",
      skill_name = huodi.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:turnOver()
  end,
})

return huodi
