local mouduan = fk.CreateSkill{
  name = "hs__mouduan",
}
mouduan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) or player.phase ~= Player.Finish then return false end
    local suits, types, play_ids = {}, {}, {}
    local logic = player.room.logic
    logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
      if e.data.phase == Player.Play then
        table.insert(play_ids, {e.id, e.end_id})
      end
      return false
    end, Player.HistoryTurn)
    logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local in_play = false
      for _, ids in ipairs(play_ids) do
        if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
          in_play = true
          break
        end
      end
      if in_play then
        local use = e.data
        if use.from == player then
          table.insertIfNeed(suits, use.card.suit)
          table.insertIfNeed(types, use.card.type)
        end
      end
    end, Player.HistoryTurn)
    return #suits >= 4 or #types >= 3
  end,
  on_cost = function(self, event, target, player, data)
    local targets = player.room:askToChooseToMoveCardInBoard(player, {prompt = "#hs__mouduan-move", cancelable = true, skill_name = mouduan.name})
    if #targets ~= 0 then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local targets = event:getCostData(self).tos
    player.room:askToMoveCardInBoard(player, { target_one = targets[1], target_two = targets[2], skill_name = self.name })
  end
})

Fk:loadTranslationTable{
  ["hs__mouduan"] = "谋断",
  [":hs__mouduan"] = "结束阶段，若你于出牌阶段内使用过四种花色或三种类别的牌，你可移动场上的一张牌。",

  ["#hs__mouduan-move"] = "谋断：你可选择两名角色，移动他们场上的一张牌",

  ["$hs__mouduan1"] = "今日起兵，渡江攻敌！",
  ["$hs__mouduan2"] = "时机已到，全军出击！。",
}

return mouduan
