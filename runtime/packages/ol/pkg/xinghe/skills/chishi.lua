local chishi = fk.CreateSkill{
  name = "chishi",
}

Fk:loadTranslationTable{
  ["chishi"] = "持室",
  [":chishi"] = "每回合限一次，当前回合角色失去其一个区域内最后一张牌后，你可以令其摸两张牌且本回合手牌上限+2。",

  ["#chishi-invoke"] = "持室：是否令 %dest 摸两张牌且本回合手牌上限+2？",

  ["$chishi1"] = "柴米油盐之细，不逊兵家之谋。",
  ["$chishi2"] = "治大家如烹小鲜，须面面俱到。",
}

chishi:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chishi.name) and player:usedSkillTimes(chishi.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from and move.from == player.room:getCurrent() and not move.from.dead then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand and move.from:isKongcheng()) or
              (info.fromArea == Card.PlayerEquip and #move.from:getCardIds("e") == 0) or
              (info.fromArea == Card.PlayerJudge and #move.from:getCardIds("j") == 0) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chishi.name,
      prompt = "#chishi-invoke::"..room:getCurrent().id,
    }) then
      event:setCostData(self, { tos = { room:getCurrent() } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getCurrent()  ---@cast to ServerPlayer
    room:addPlayerMark(to, MarkEnum.AddMaxCardsInTurn, 2)
    to:drawCards(2, chishi.name)
  end,
})

chishi:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(target, 2)
    end) >= 0
  end,
})

return chishi
