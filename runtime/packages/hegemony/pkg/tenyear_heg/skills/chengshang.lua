local chengshang = fk.CreateSkill{
  name = "ty_heg__chengshang",
}

Fk:loadTranslationTable{
  ["ty_heg__chengshang"] = "承赏",
  [":ty_heg__chengshang"] = "每阶段限一次，当你于出牌阶段内使用指定有与你势力不同或未确定势力角色为目标的牌结算后，若此牌未造成伤害，"..
  "你可获得牌堆中所有与此牌花色点数相同的牌。若你没有因此获得牌，此技能视为此阶段未发动过。",

  ["#ty_heg__chengshang-invoke"] = "承赏：你可以获得牌堆中所有的 %arg 牌",

  ["$ty_heg__chengshang1"] = "嘉其抗直，甚爱待之。",
  ["$ty_heg__chengshang2"] = "为国鞠躬，必受封赏。",
}

local H = require "packages.hegemony.util"

chengshang:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengshang.name) and player.phase == Player.Play and
      table.find(data.tos, function(p)
        return not H.compareKingdomWith(p, player)
      end) and
      not data.damageDealt and data.card.suit ~= Card.NoSuit and
      player:usedSkillTimes(chengshang.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chengshang.name,
      prompt = "#ty_heg__chengshang-invoke:::"..data.card:getSuitCompletedString(true)
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|"..data.card:getNumberStr().."|"..data.card:getSuitString(), 9)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, chengshang.name, nil, false, player)
    else
      player:clearSkillHistory(chengshang.name, Player.HistoryPhase)
    end
  end,
})

return chengshang
