local guying = fk.CreateSkill {
  name = "guying",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guying"] = "固营",
  [":guying"] = "锁定技，每回合限一次，当你于回合外因使用、打出或弃置一次性仅失去一张牌后，当前回合角色须选择一项："..
  "1.随机交给你一张牌；2.你获得此牌（若为装备则使用之）。准备阶段，你须弃置X张牌（X为本技能发动次数），然后重置此技能发动次数。",

  ["guying_get"] = "令%src获得%arg",
  ["guying_give"] = "随机交给%src一张牌",
  ["#guying-invoke"] = "固营：请选择 %src 执行的一项",
  ["#guying-use"] = "固营：请使用%arg",

  ["$guying1"] = "我军之营，犹如磐石之固！",
  ["$guying2"] = "深壁固垒，敌军莫敢来侵！",
}

guying:addEffect(fk.AfterCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(guying.name) and player.room.current ~= player and not player.room.current.dead and
      player:usedSkillTimes(guying.name, Player.HistoryTurn) == 0 then
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player and
          table.contains({ fk.ReasonUse, fk.ReasonResponse, fk.ReasonDiscard }, move.moveReason) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              n = n + 1
            end
          end
        end
      end
      return n == 1
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { player.room.current } })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local id
    for _, move in ipairs(data) do
      if move.from == player and
        table.contains({ fk.ReasonUse, fk.ReasonResponse, fk.ReasonDiscard }, move.moveReason) then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            id = info.cardId
            break
          end
        end
      end
    end
    local choices = {}
    if room:getCardArea(id) == Card.Processing then
      table.insert(choices, "guying_get:"..player.id.."::"..Fk:getCardById(id, true):toLogString())
    end
    if not room.current:isNude() then
      table.insert(choices, "guying_give:"..player.id)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(room.current, {
      choices = choices,
      skill_name = guying.name,
      prompt = "#guying-invoke:"..player.id,
    })
    if choice:startsWith("guying_get") then
      room:obtainCard(player, id, true, fk.ReasonJustMove, nil, guying.name)
      if player.dead or not table.contains(player:getCardIds("h"), id) then return end
      local card = Fk:getCardById(id)
      if card.type == Card.TypeEquip then
        if player:canUseTo(card, player) then
          room:useCard({
            from = player,
            tos = {player},
            card = card,
          })
        else
          room:askToUseRealCard(player, {
            pattern = {card.id},
            skill_name = guying.name,
            prompt = "#guying-use:::"..card:toLogString(),
            cancelable = false,
          })
        end
      end
    else
      room:obtainCard(player, room:tableRandomPick(room.current:getCardIds("he")), false, fk.ReasonGive, room.current, guying.name)
    end
  end,
})

guying:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(guying.name) and player.phase == Player.Start and
      player:usedSkillTimes(guying.name, Player.HistoryGame) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = player:usedSkillTimes(guying.name, Player.HistoryGame) - 1
    player:setSkillUseHistory(guying.name, 0, Player.HistoryGame)
    room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = guying.name,
      cancelable = false,
    })
  end,
})

return guying
