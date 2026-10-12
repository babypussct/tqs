local chengzhao = fk.CreateSkill{
  name = "chengzhao",
}

Fk:loadTranslationTable{
  ["chengzhao"] = "承诏",
  [":chengzhao"] = "一名角色的结束阶段，若你本回合获得过至少两张牌，你可以与一名其他角色拼点，若你赢，视为你对其使用一张无视防具的【杀】。",

  ["#chengzhao-choose"] = "承诏：与一名角色拼点，若你赢，视为对其使用一张无视防具的【杀】",

  ["$chengzhao1"] = "定当为皇上诛杀首害！",
  ["$chengzhao2"] = "此诏字字诛心，岂能不斩曹贼！",
}

chengzhao:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chengzhao.name) and target.phase == Player.Finish and not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.PlayerHand and move.to == player then
            n = n + #move.moveInfo
            if n > 1 then
              return true
            end
          end
        end
      end, Player.HistoryTurn)
      return n > 1
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = chengzhao.name,
      prompt = "#chengzhao-choose",
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
    local pindian = player:pindian({to}, chengzhao.name)
    if pindian.results[to].winner == player and not (player.dead or to.dead) then
      local slash = Fk:cloneCard("slash")
      slash.skillName = chengzhao.name
      if player:canUseTo(slash, to, { bypass_times = true, bypass_distances= true }) then
        room:useCard{
          from = player,
          card = slash,
          tos = {to},
          extraUse = true,
          extra_data = {
            chengzhao = player,
          }
        }
      end
    end
  end,
})
chengzhao:addEffect(fk.TargetSpecified, {
  can_refresh = function (self, event, target, player, data)
    return not player.dead and (data.extra_data or {}).chengzhao == player and not data.to.dead
  end,
  on_refresh = function (self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

return chengzhao
