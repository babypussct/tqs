local falu = fk.CreateSkill {
  name = "falu",
}

Fk:loadTranslationTable{
  ["falu"] = "法箓",
  [":falu"] = "当你失去一张手牌时，记录此牌花色（只记录最近三次）。"..
  "当记录的三个花色相同时，你移除记录花色并从牌堆中获得其他三种花色的牌各一张；"..
  "当记录的三个花色各不相同时，你移除记录花色并可以令一名角色失去或回复1点体力。",

  ["@falu"] = "法箓",
  ["#falu-choose"] = "法箓：选择一名角色，令其失去或回复1点体力",
  ["falu_losehp"] = "令%dest失去1点体力",
  ["falu_recover"] = "令%dest回复1点体力",

  ["$falu1"] = "求法之道，以司箓籍。",
  ["$falu2"] = "取舍有法，方得其法。",
}

falu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(falu.name) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
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
    local skillName = falu.name
    local mark = player:getTableMark("@falu")
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            table.insert(mark, Fk:getCardById(info.cardId, true):getSuitString(true))
          end
        end
      end
    end
    if #mark > 2 then
      mark = { mark[#mark-2], mark[#mark-1], mark[#mark] }
      room:setPlayerMark(player, "@falu", mark)

      if mark[1] == mark[2] and mark[2] == mark[3] then
        room:setPlayerMark(player, "@falu", 0)
        if player:hasSkill("zhenyi") then
          room:addTableMarkIfNeed(player, "@zhenyi", mark[1])
        end

        --实测从牌堆底开始检索，背面移动
        local suits = {"spade", "club", "heart", "diamond"}
        table.removeOne(suits, string.sub(mark[1], 5))
        local cards = {}
        local id = -1
        for i = #room.draw_pile, 1, -1 do
          id = room.draw_pile[i]
          if table.removeOne(suits, Fk:getCardById(id):getSuitString()) then
            table.insert(cards, id)
            if #suits == 0 then break end
          end
        end
        if #cards > 0 then
          room:obtainCard(player, cards, false, fk.ReasonJustMove, player, skillName)
        end

      elseif mark[1] ~= mark[2] and mark[2] ~= mark[3] and mark[1] ~= mark[3] then
        room:setPlayerMark(player, "@falu", 0)
        if player:hasSkill("zhenyi") and player:hasSkill("dianhua", true) and player:getMark("dianhua") < 4 then
          room:addPlayerMark(player, "dianhua")
        end
        local tos = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = room.alive_players,
          skill_name = skillName,
          prompt = "#falu-choose",
          cancelable = true,
        })
        if #tos > 0 then
          local choice = room:askToChoice(player, {
            choices = {"falu_losehp::" .. tos[1].id, "falu_recover::" .. tos[1].id},
            skill_name = skillName
          })
          if choice:startsWith("falu_losehp") then
            room:loseHp(tos[1], 1, skillName)
          elseif tos[1]:isWounded() then
            room:recover({
              who = tos[1],
              num = 1,
              recoverBy = player,
              skillName = skillName,
            })
          end
        end
      end
    else
      room:setPlayerMark(player, "@falu", mark)
    end
  end,
})

falu:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@falu", 0)
end)

return falu
