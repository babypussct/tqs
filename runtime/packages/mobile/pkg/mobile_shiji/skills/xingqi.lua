local xingqi = fk.CreateSkill {
  name = "xingqi",
}

Fk:loadTranslationTable{
  ["xingqi"] = "星启",
  [":xingqi"] = "当你使用一张不为延时锦囊的牌时，若没有此牌名的“备”，则记录此牌牌名为“备”。结束阶段，你可以移除一个“备”，获得牌堆中一张同名牌。",

  ["@$wangling_bei"] = "备",
  ["#xingqi-invoke"] = "星启：你可以移除一个“备”，获得牌堆中一张同名牌",

  ["$xingqi1"] = "先谋后事者昌，先事后谋者亡！",
  ["$xingqi2"] = "司马氏虽权尊势重，吾等徐图亦无不可！",
}

local U = require "packages.utility.utility"

xingqi:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingqi.name) and
      data.card.sub_type ~= Card.SubtypeDelayedTrick and
      not table.contains(player:getTableMark("@$wangling_bei"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addTableMark(player, "@$wangling_bei", data.card.trueName)
  end,
})
xingqi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingqi.name) and
      player.phase == Player.Finish and player:getMark("@$wangling_bei") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local choice = U.askForChooseCardNames(player.room, player, player:getTableMark("@$wangling_bei"), 1, 1, xingqi.name,
      "#xingqi-invoke", nil, true)
    if #choice > 0 then
      event:setCostData(self, {choice = choice[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:removeTableMark(player, "@$wangling_bei", choice)
    local cards = room:getCardsFromPileByRule(choice, 1, "drawPile")
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, xingqi.name, nil, false, player)
    end
  end,
})

return xingqi
