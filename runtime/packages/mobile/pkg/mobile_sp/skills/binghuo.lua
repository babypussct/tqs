local binghuo = fk.CreateSkill {
  name = "binghuo",
}

Fk:loadTranslationTable{
  ["binghuo"] = "兵祸",
  [":binghuo"] = "一名角色结束阶段，若你本回合发动〖集兵〗使用或打出过“兵”，你可以令一名角色判定，若结果为黑色，你对其造成1点雷电伤害。",

  ["#binghuo-choose"] = "兵祸：令一名角色判定，若为黑色，你对其造成1点雷电伤害",

  ["$binghuo1"] = "黄巾既起，必灭不义之师！",
  ["$binghuo2"] = "诛官杀吏，尽诛朝廷爪牙！",
}

binghuo:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(binghuo.name) and target.phase == Player.Finish then
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.from == player and table.contains(use.card.skillNames, "jibing")
      end, Player.HistoryTurn) > 0 then
        return true
      end
      if #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e) 
        local use = e.data
        return use.from == player and table.contains(use.card.skillNames, "jibing")
      end, Player.HistoryTurn) > 0 then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(
      player,
      {
        targets = player.room:getAlivePlayers(false),
        min_num = 1,
        max_num = 1,
        prompt = "#binghuo-choose",
        skill_name = binghuo.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = binghuo.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local judge = {
      who = to,
      reason = skillName,
      pattern = ".|.|black",
    }
    room:judge(judge)
    if judge:matchPattern() and to:isAlive() then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = skillName,
      }
    end
  end,
})

return binghuo
