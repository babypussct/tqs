local qianxin = fk.CreateSkill {
  name = "qianxinz",
}

Fk:loadTranslationTable{
  ["qianxinz"] = "遣信",
  [":qianxinz"] = "出牌阶段限一次，若牌堆中没有“信”，你可以令所有角色同时选择一张手牌，并将此牌随机置入牌堆的上半部分，称为“信”。"..
  "当你获得“信”时，你将手牌摸至四张，并可以令当前回合角色手牌上限-2。当其他角色获得“信”时，你摸一张牌。",

  ["#qianxinz"] = "遣信：令所有角色同时将一张手牌作为“信”置入牌堆",
  ["#qianxin-ask"] = "遣信：请将一张手牌作为“信”置入牌堆",
  ["@zhanggong_mail"] = "信",
  ["#qianxinz-invoke"] = "遣信：是否令 %dest 本回合手牌上限-2？",

  ["$qianxinz1"] = "遣信求援，前后合围。",
  ["$qianxinz2"] = "信中所言，吾知计策一二。",
}

qianxin:addEffect("active", {
  anim_type = "control",
  prompt = "#qianxinz",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0 and
      #player:getTableMark("zhanggong_mail") == 0
  end,
  card_filter = Util.FalseFunc,
  on_cost = function(self, player, data)
    return { tos = player.room:getAlivePlayers() }
  end,
  on_use = function(self, room, effect)
    local player = effect.from

    local targets = table.filter(room.alive_players, function(p)
      return not p:isKongcheng()
    end)
    if #targets == 0 then return end
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qianxin.name,
      prompt = "#qianxin-ask",
      cancelable = false,
    })

    local move, indexes, cards = {}, {}, {}

    --角色和卡牌是一一对应的，可以通过打乱角色来实现洗牌
    room:shuffleTable(targets)
    local pileLen = #room.draw_pile // 2 + 1
    local cardsLen = #targets

    for _ = 1, cardsLen, 1 do
      table.insert(indexes, room:random(pileLen))
    end
    table.sort(indexes, function(a, b) return a > b end)

    for i = 1, #targets do
      local ids = result[targets[i]]
      table.insert(cards, ids[1])
      table.insert(move, {
        ids = ids,
        from = targets[i],
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        proposer = targets[i],
        skillName = qianxin.name,
        drawPilePosition = indexes[i],
      })
    end
    room:setPlayerMark(player, "zhanggong_mail", cards)
    room:setPlayerMark(player, "@zhanggong_mail", #cards)
    room:moveCards(table.unpack(move))
  end,
})

qianxin:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qianxin.name) then
      local cards = player:getTableMark("zhanggong_mail")
      if #cards == 0 then return false end
      for _, move in ipairs(data) do
        if move.to and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            --待定：是否需要验证牌仍在目标区域？
            if table.contains(cards, info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local containsSelf = false
    local cards = player:getTableMark("zhanggong_mail")
    for _, move in ipairs(data) do
      if move.to and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if table.removeOne(cards, info.cardId) and move.to == player then
            containsSelf = true
          end
        end
      end
    end
    room:setPlayerMark(player, "zhanggong_mail", #cards > 0 and cards or 0)
    room:setPlayerMark(player, "@zhanggong_mail", #cards)
    if containsSelf then
      if player:getHandcardNum() < 4 then
        player:drawCards(4 - player:getHandcardNum(), qianxin.name)
        if player.dead then return end
      end
      local current = room:getCurrent()
      if current and not current.dead and
        room:askToSkillInvoke(player, {
          skill_name = qianxin.name,
          prompt = "#qianxinz-invoke::"..current.id,
        }) then
        room:addPlayerMark(current, MarkEnum.MinusMaxCardsInTurn, 2)
      end
    else
      player:drawCards(1, qianxin.name)
    end
  end,
})

qianxin:addLoseEffect(function(self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@zhanggong_mail", 0)
  room:setPlayerMark(player, "zhanggong_mail", 0)
end)

return qianxin
