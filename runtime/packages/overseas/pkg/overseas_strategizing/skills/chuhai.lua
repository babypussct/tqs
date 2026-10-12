local chuhai = fk.CreateSkill {
  name = "os__chuhai",
  tags = { Skill.Quest }
}

Fk:loadTranslationTable{
  ["os__chuhai"] = "除害",
  [":os__chuhai"] = "<a href='os__quest'>使命技</a>，令两名其他角色进入濒死状态。<br>"..
  "⬤　成功：当前回合结束时，废除你的判定区，然后每名其他角色依次交给你一张牌。<br>"..
  "⬤　完成前：其他角色交给你牌后，你将其中一张置入弃牌堆。",

  ["@os__chuhai"] = "除害",
  ["#os__chuhai-ask"] = "除害：交给 %src 一张牌",
  ["#os__chuhai-discard"] = "除害：你需将其中一张牌置入弃牌堆",

  ["$os__chuhai1"] = "快快闪开，伤到你们可就不好了，哈哈哈！",
  ["$os__chuhai2"] = "你自己撞上来的，这可怪不得小爷我！",
  ["$os__chuhai3"] = "小小孽畜，还不伏诛？",
  ["$os__chuhai4"] = "有我在此，安敢为害！",
  ["$os__chuhai5"] = "此番不成，明日再战！",
}

chuhai:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getQuestSkillState(chuhai.name) == "succeed" and player:getMark("@os__chuhai") >= 2
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, chuhai.name, "control")
    player:broadcastSkillInvoke(chuhai.name, math.random(3, 4))
    room:setPlayerMark(player, "@os__chuhai", 0)
    room:invalidateSkill(player, chuhai.name)
    room:abortPlayerArea(player, { Player.JudgeSlot })
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      if not p.dead and not p:isNude() then
        local card = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = chuhai.name,
          cancelable = false,
          prompt = "#os__chuhai-ask:" .. player.id,
        })
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, chuhai.name, nil, false, player)
        end
      end
    end
  end,
})

chuhai:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chuhai.name) then
      local ids = {}
      for _, move in ipairs(data) do
        if move.to == player and move.moveReason == fk.ReasonGive then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, chuhai.name, "negative")
    player:broadcastSkillInvoke(chuhai.name, 5)
    room:updateQuestSkillState(player, chuhai.name, true)
    local card = event:getCostData(self).cards
    if #card > 1 then
      card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = chuhai.name,
        cancelable = false,
        pattern = tostring(Exppattern{ id = card }),
        prompt = "#os__chuhai-discard",
      })
    end
    room:moveCardTo(card, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, chuhai.name, nil, true, player)
  end,
})

chuhai:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chuhai.name) and data.damage and data.damage.from == player and
      player:getQuestSkillState(chuhai.name) ~= "succeed" and
      target ~= player and not table.contains(player:getTableMark("_os__chuhai"), target.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, chuhai.name, "offensive")
    player:broadcastSkillInvoke(chuhai.name, math.random(2))
    room:addTableMark(player, "_os__chuhai", target.id)
    room:addPlayerMark(player, "@os__chuhai")
    if player:getMark("@os__chuhai") > 1 then
      room:updateQuestSkillState(player, chuhai.name, true)
      room:updateQuestSkillState(player, chuhai.name, false)
    end
  end,
})

chuhai:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@os__chuhai", 0)
end)

return chuhai
