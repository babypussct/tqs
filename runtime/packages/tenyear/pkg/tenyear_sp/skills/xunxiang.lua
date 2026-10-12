local xunxiang = fk.CreateSkill {
  name = "xunxiang",
  max_branches_use_time = {
    ["spade"] = {
      [Player.HistoryTurn] = 1
    },
    ["heart"] = {
      [Player.HistoryTurn] = 1
    },
    ["club"] = {
      [Player.HistoryTurn] = 1
    },
    ["diamond"] = {
      [Player.HistoryTurn] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["xunxiang"] = "寻香",
  [":xunxiang"] = "每回合每种花色各限一次，当你使用的牌结算结束后，你可以观看牌堆顶的四张牌，"..
  "获得其中与使用的牌花色相同的牌，本局游戏你使用过的牌的花色首次达到2与4时，此技能观看的牌数+1。",

  ["#xunxiang-invoke"] = "寻香：观看牌堆顶的%arg张牌，获得其中的所有%arg2牌",

  ["$xunxiang1"] = "",
  ["$xunxiang2"] = "",
}

xunxiang:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(xunxiang.name) and
      xunxiang:withinBranchTimesLimit(player, data.card:getSuitString(), Player.HistoryTurn)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = xunxiang.name,
      prompt = "#xunxiang-invoke:::"..tostring(4+#player:getTableMark(xunxiang.name)//2)..":"..data.card:getSuitString()
    }) then
      event:setCostData(self, { history_branch = data.card:getSuitString() })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local skillName = xunxiang.name
    local room = player.room
    local cards = room:getNCards(4+#player:getTableMark(xunxiang.name)//2)
    room:viewCards(player, {
      cards = cards,
      skill_name = skillName
    })
    local suit = data.card.suit
    cards = table.filter(cards, function(id)
      return Fk:getCardById(id).suit == suit
    end)
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, skillName)
    end
  end,
})

xunxiang:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(xunxiang.name) and data.card.suit ~= Card.NoSuit and
      not table.contains(player:getTableMark(xunxiang.name), data.card.suit)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, xunxiang.name, data.card.suit)
  end,
})

xunxiang:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, xunxiang.name, 0)
end)

xunxiang:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return xunxiang
