local yongjin = fk.CreateSkill {
  name = "os_ex__yongjin",
}

Fk:loadTranslationTable{
  ["os_ex__yongjin"] = "勇进",
  [":os_ex__yongjin"] = "每个阶段结束时，若你于此阶段失去过牌，你可以视为对任意名本阶段失去牌数与你相同的角色使用一张无距离次数限制的【杀】；"..
  "此【杀】造成伤害后，你随机恢复一个装备栏，若没有可恢复的装备栏，改为将弃牌堆中随机一张装备牌置入你空置的装备栏。",

  ["#os_ex__yongjin-choose"] = "勇进：视为对其中任意名角色使用【杀】，造成伤害则恢复装备栏",

  ["$os_ex__yongjin1"] = "",
  ["$os_ex__yongjin2"] = "",
}

yongjin:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yongjin.name) and
      player.phase >= Player.Start and player.phase <= Player.Finish then
      local room = player.room
      local dat = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                dat[move.from] = (dat[move.from] or 0) + 1
              end
            end
          end
        end
      end, Player.HistoryPhase)
      if dat[player] then
        local targets = {}
        local slash = Fk:cloneCard("slash")
        slash.skillName = yongjin.name
        for p, n in pairs(dat) do
          if p ~= player and n == dat[player] and player:canUseTo(slash, p, { bypass_distances = true, bypass_times = true }) then
            table.insert(targets, p)
          end
        end
        if #targets > 0 then
          event:setCostData(self, { tos = targets })
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos or {}
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = #targets,
      targets = targets,
      skill_name = yongjin.name,
      prompt = "#os_ex__yongjin-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tos = event:getCostData(self).tos or {}
    player.room:useVirtualCard("slash", nil, player, tos, yongjin.name, true)
  end,
})

yongjin:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.card and table.contains(data.card.skillNames, yongjin.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if #player.sealedSlots > 0 then
      room:resumePlayerArea(player, { room:tableRandomPick(player.sealedSlots) })
    else
      local cards = table.filter(room.discard_pile, function (id)
        return player:canMoveCardIntoEquip(id, false)
      end)
      if #cards > 0 then
        room:moveCardIntoEquip(player, room:tableRandomPick(cards), yongjin.name, false, player)
      end
    end
  end,
})

return yongjin
