local feixiong = fk.CreateSkill {
  name = "feixiong",
}

Fk:loadTranslationTable{
  ["feixiong"] = "飞熊",
  [":feixiong"] = "出牌阶段开始时，你可以与一名其他角色拼点，拼点赢的角色对拼点未赢的角色造成1点伤害。",

  ["#feixiong-choose"] = "飞熊：与一名其他角色拼点，赢者对对方造成1点伤害",
}

feixiong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(feixiong.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#feixiong-choose",
      skill_name = feixiong.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({ to }, feixiong.name)
    local from = pindian.results[to].winner
    if from then
      to = from == player and to or player
      if not to.dead then
        room:damage{
          from = from,
          to = to,
          damage = 1,
          skillName = feixiong.name,
        }
      end
    end
  end,
})

return feixiong
