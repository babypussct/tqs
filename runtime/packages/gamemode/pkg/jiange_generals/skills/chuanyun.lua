local chuanyun = fk.CreateSkill {
  name = "jiange__chuanyun",
}

Fk:loadTranslationTable{
  ["jiange__chuanyun"] = "穿云",
  [":jiange__chuanyun"] = "结束阶段，你可以对一名体力值大于你的角色造成1点伤害。",

  ["#jiange__chuanyun-choose"] = "穿云：你可以对一名体力值大于你的角色造成1点伤害",
}

chuanyun:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chuanyun.name) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return p.hp > player.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p.hp > player.hp
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#jiange__chuanyun-choose",
      skill_name = chuanyun.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = event:getCostData(self).tos[1],
      damage = 1,
      skillName = chuanyun.name,
    }
  end,
})

return chuanyun
