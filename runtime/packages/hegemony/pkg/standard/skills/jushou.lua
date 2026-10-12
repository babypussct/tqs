local jushou = fk.CreateSkill{
  name = "hs__jushou",
}

Fk:loadTranslationTable{
  ["hs__jushou"] = "据守",
  [":hs__jushou"] = "结束阶段，你可摸X张牌（X为势力数），然后弃置一张手牌，若以此法弃置的牌为装备牌，则改为你使用之。若X大于3，则你将武将牌叠置。",

  ["#hs__jushou-ask"] = "据守：选择使用手牌中的一张装备牌或弃置手牌中的一张非装备牌",

  ["$hs__jushou1"] = "我先休息一会儿！",
  ["$hs__jushou2"] = "尽管来吧！",
}

local H = require "packages.hegemony.util"

jushou:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 0
    for _, v in pairs(H.getKingdomPlayersNum(room)) do
      if v and v > 0 then
        num = num + 1
      end
    end
    room:drawCards(player, num, self.name)
    if player.dead then return false end
    local cards = {}
    for _, id in pairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeEquip and not player:prohibitUse(card)) or
        (card.type ~= Card.TypeEquip and not player:prohibitDiscard(card)) then
        table.insert(cards, id)
      end
    end
    if #cards == 0 then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = jushou.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#hs__jushou-ask",
      cancelable = false,
    })[1]
    if card then
      if Fk:getCardById(card).type == Card.TypeEquip then
        room:useCard{
          from = player,
          tos = { player },
          card = Fk:getCardById(card),
        }
      else
        room:throwCard(card, jushou.name, player, player)
      end
    end
    if player.dead then return false end
    if num > 3 then player:turnOver() end
  end,
})

return jushou
