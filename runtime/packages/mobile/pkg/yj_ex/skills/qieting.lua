local qieting = fk.CreateSkill{
  name = "m_ex__qieting",
}

Fk:loadTranslationTable{
  ["m_ex__qieting"] = "窃听",
  [":m_ex__qieting"] = "其他角色的回合结束后，若其没有于此回合内对另一名角色造成过伤害，你可以选择："..
    "1.观看其两张手牌并获得其中一张牌；2.将其装备区里的一张牌置入你的装备区；3.摸一张牌。",

  ["m_ex__qieting_pry"] = "观看%dest两张手牌并获得其中一张",
  ["m_ex__qieting_move"] = "移动%dest装备区里的一张牌",

  ["$m_ex__qieting1"] = "密言？哼！早已入我耳中。",
  ["$m_ex__qieting2"] = "此子不除，久必为患！",
}

qieting:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qieting.name) and player ~= target and #player.room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data
      return target == damage.from and target ~= damage.to
    end, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1", "Cancel"}
    if not target.dead then
      if target:canMoveCardsInBoardTo(player, "e") then
        table.insert(choices, "m_ex__qieting_move::" .. target.id)
      end
      if not target:isKongcheng() then
        table.insert(choices, "m_ex__qieting_pry::" .. target.id)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qieting.name,
      all_choices = {"m_ex__qieting_pry::" .. target.id, "m_ex__qieting_move::" .. target.id, "draw1", "Cancel"}
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice:split(":")[1], tos = (choice == "draw1" and {} or {target})})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "draw1" then
      room:notifySkillInvoked(player, qieting.name, "drawcard")
      player:broadcastSkillInvoke(qieting.name)
      player:drawCards(1, qieting.name)
      return false
    end
    room:notifySkillInvoked(player, qieting.name, "control", {target.id})
    player:broadcastSkillInvoke(qieting.name)
    if choice == "m_ex__qieting_pry" then
      local handcards = target:getCardIds("h")
      if #handcards > 0 then
        local id = handcards[1]
        if #handcards > 1 then
          id = player.room:askToChooseCard(player, {
            target = target,
            flag = {
              card_data = {
                { "$Hand", room:tableRandomPick(handcards, 2) }
              }
            },
            skill_name = qieting.name
          })
        end
        player.room:obtainCard(player, id, false, fk.ReasonPrey, player, qieting.name)
      end
    elseif choice == "m_ex__qieting_move" then
      player.room:askToMoveCardInBoard(player, {
        target_one = target,
        target_two = player,
        skill_name = qieting.name,
        flag = "e",
        move_from = target,
      })
    end
  end,
})

return qieting
