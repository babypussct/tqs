local zhenfu = fk.CreateSkill {
  name = "zhenfu",
}

Fk:loadTranslationTable{
  ["zhenfu"] = "镇抚",
  [":zhenfu"] = "结束阶段，若你本回合因弃置失去过牌，你可以令一名其他角色获得1点护甲。",

  ["#zhenfu-choose"] = "镇抚：你可以令一名其他角色获得1点护甲",

  ["$zhenfu1"] = "储资粮，牧良畜，镇外贼，抚黎庶。",
  ["$zhenfu2"] = "通民户十万余众，镇大小夷虏晏息。",
}

zhenfu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and target:hasSkill(zhenfu.name) and player.phase == Player.Finish then
      local events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if
            move.from == player and
            move.moveReason == fk.ReasonDiscard and
            table.find(move.moveInfo, function(info)
              return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
            end)
          then
            return true
          end
        end
      end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(
      player,
      {
        targets = player.room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#zhenfu-choose",
        skill_name = zhenfu.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeShield(event:getCostData(self).tos[1], 1)
  end,
})

return zhenfu
