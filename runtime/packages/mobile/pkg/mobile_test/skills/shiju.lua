local shiju = fk.CreateSkill {
  name = "mobile__shiju",
  tags = { Skill.Compulsory },
  related_skills = { "kubai" },
}

Fk:loadTranslationTable{
  ["mobile__shiju"] = "势举",
  [":mobile__shiju"] = "锁定技，当你使用牌结算结束后，若此牌与你使用此牌前被使用的上一张牌：类别相同，你获得牌堆顶一张牌；" ..
  "花色相同，你获得牌堆底一张牌。<a href='#ChengShi'>乘势</a>：若牌名也相同，你获得或升级技能〖枯白〗。",

  ["$mobile__shiju1"] = "凡家之衣帛，必先书而后练之。",
  ["$mobile__shiju2"] = "临池学书，池水尽墨。",
  ["$mobile__shiju3"] = "坐忘尘鞅，笔与神遇。",
}

shiju:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(shiju.name)) then
      return false
    end

    local logic = player.room.logic
    local currentEventId = logic:getCurrentEvent().id
    local use = logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
      return e.id < currentEventId
    end, nil, Player.HistoryGame)

    if #use > 0 then
      local useData = use[1].data
      if not (useData.card.type == data.card.type or useData.card:compareSuitWith(data.card)) then
        return false
      end

      local audioTable = { 1, 2 }
      if
        useData.card.type == data.card.type and
        useData.card:compareSuitWith(data.card) and
        useData.card.trueName == data.card.trueName
      then
        audioTable = { 3 }
      end

      event:setCostData(self, { lastCard = useData.card, audio_index = player.room:tableRandomPick(audioTable) })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = shiju.name
    local room = player.room
    local lastCard = event:getCostData(self).lastCard
    if lastCard.type == data.card.type then
      room:obtainCard(player, room:getNCards(1), false, fk.ReasonPrey, player, skillName)
    end

    if not player:isAlive() then
      return false
    end

    if lastCard:compareSuitWith(data.card) then
      room:obtainCard(player, room:getNCards(1, "bottom"), false, fk.ReasonPrey, player, skillName)
    end

    if
      lastCard.type == data.card.type and
      lastCard:compareSuitWith(data.card) and
      lastCard.trueName == data.card.trueName
    then
      local kubaiLevel = player:getMark("@kubai_level")
      if player:hasSkill("kubai", true) and kubaiLevel < 3 then
        room:setPlayerMark(player, "kubai_record-turn", 0)
        if kubaiLevel == 0 then
          room:setPlayerMark(player, "@kubai_level", 2)
        else
          room:addPlayerMark(player, "@kubai_level")
        end
      else
        room:handleAddLoseSkills(player, "kubai")
      end
    end
  end
})

return shiju
