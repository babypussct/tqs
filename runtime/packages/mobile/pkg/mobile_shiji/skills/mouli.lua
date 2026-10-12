local mouli = fk.CreateSkill {
  name = "mouli",
}

Fk:loadTranslationTable{
  ["mouli"] = "谋立",
  [":mouli"] = "出牌阶段限一次，你可以令一名其他角色移除你的一个“备”，然后其获得牌堆中一张同名牌。",

  ["#mouli"] = "谋立：令一名其他角色移除你的一个“备”，其获得牌堆中一张同名牌",
  ["#mouli-choice"] = "谋立：移除 %src 的一个“备”，你获得牌堆中一张同名牌",

  ["$mouli1"] = "澄汰王室，迎立宗子！",
  ["$mouli2"] = "僣孽为害，吾岂可谋而不行？",
}

local U = require "packages.utility.utility"

mouli:addEffect("active", {
  anim_type = "support",
  prompt = "#mouli",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(mouli.name, Player.HistoryPhase) == 0 and #player:getTableMark("@$wangling_bei") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choice = U.askForChooseCardNames(room, target, player:getTableMark("@$wangling_bei"), 1, 1, mouli.name,
      "#mouli-choice:"..player.id, nil, false)[1]
    room:removeTableMark(player, "@$wangling_bei", choice)
    local cards = room:getCardsFromPileByRule(choice, 1, "drawPile")
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonJustMove, mouli.name, nil, false, target)
    end
  end,
})

return mouli
