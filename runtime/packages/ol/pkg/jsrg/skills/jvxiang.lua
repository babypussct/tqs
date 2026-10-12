local jvxiang = fk.CreateSkill {
  name = "ol__jvxiang",
}

Fk:loadTranslationTable{
  ["ol__jvxiang"] = "拒降",
  [":ol__jvxiang"] = "每回合限一次，当你于摸牌阶段外获得牌后，你可以弃置这些牌，你每以此法弃置一张牌，"..
  "当前回合角色本回合使用【杀】的次数上限便+1。",

  ["#ol__jvxiang-invoke"] = "拒降：是否弃置这些牌，令 %dest 本回合使用【杀】次数上限增加？",

  ["$ol__jvxiang1"] = "非讨之无以惩恶，岂容逆辈乞降？",
  ["$ol__jvxiang2"] = "利则进战，钝则乞降，逆贼此可行邪？",
}

jvxiang:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jvxiang.name) and player:usedSkillTimes(jvxiang.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and player.phase ~= Player.Draw then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jvxiang.name,
      prompt = "#ol__jvxiang-invoke::"..room.current.id,
    }) then
      event:setCostData(self, {tos = {room.current}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand and player.phase ~= Player.Draw then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) and not player:prohibitDiscard(info.cardId) then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    if #cards > 0 then
      room:throwCard(cards, jvxiang.name, player, player)
      if not room.current.dead then
        room:addPlayerMark(room.current, MarkEnum.SlashResidue.."-turn", #cards)
      end
    end
  end,
})

return jvxiang
