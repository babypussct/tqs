local duoyue = fk.CreateSkill{
  name = "duoyue",
}

Fk:loadTranslationTable{
  ["duoyue"] = "掇月",
  [":duoyue"] = "出牌阶段开始时，你可以进行至多三次拼点，你可令赢的角色摸X张牌（X为当前拼点次数）。若你赢，你可以改为对一名角色造成1点伤害" ..
  "并终止后续拼点。",

  ["#duoyue-choose"] = "掇月：与一名角色拼点，你可令赢的角色摸%arg张牌，若你赢可以改为造成伤害",
  ["#duoyue-damage"] = "掇月：你可放弃摸%arg张牌改为对一名角色造成1点伤害，终止后续拼点",
  ["#duoyue-draw"] = "掇月：你可令 %dest 摸%arg张牌",

  ["$duoyue1"] = "月升，月升，乌鹊绕匝天下惊！",
  ["$duoyue2"] = "月下，举世皆白，唯我独黑！",
}

duoyue:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duoyue.name) and player.phase == Player.Play and
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
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = duoyue.name,
      prompt = "#duoyue-choose:::1",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]

    for n = 1, 3 do
      local pindian = player:pindian({to}, duoyue.name)
      local winner = pindian.results[to].winner
      if winner and not winner.dead then
        if winner == player then
          local victim = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = room.alive_players,
            skill_name = duoyue.name,
            prompt = "#duoyue-damage:::" .. n,
            cancelable = true,
          })
          if #victim > 0 then
            victim = victim[1]
            room:damage{
              from = player,
              to = victim,
              damage = 1,
              skillName = duoyue.name,
            }
            return
          end
        end

        if
          player:isAlive() and
          room:askToSkillInvoke(
            player,
            { skill_name = duoyue.name, prompt = "#duoyue-draw::" .. winner.id .. ":" .. n }
          )
        then
          winner:drawCards(n, duoyue.name)
        end
      end
      if n == 3 or player.dead then
        return
      end

      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return player:canPindian(p)
      end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = duoyue.name,
        prompt = "#duoyue-choose:::".. (n + 1),
      })

      if #tos == 0 then
        break
      end

      to = tos[1]
    end
  end,
})

return duoyue
