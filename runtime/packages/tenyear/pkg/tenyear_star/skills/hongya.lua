
local hongya = fk.CreateSkill {
  name = "hongya",
}

Fk:loadTranslationTable{
  ["hongya"] = "弘雅",
  [":hongya"] = "每回合限两次，当你成为其他角色使用牌的目标时，你可以重铸一张比其使用的牌点数更大的手牌，令其使用的牌对你无效；"..
  "若你重铸的牌点数为你手牌中点数最大的牌，则你额外摸X张牌（X为你手牌中缺少的花色数）。",

  ["#hongya-ask"] = "弘雅：你可以重铸一张点数大于%arg的手牌，令此%arg2对你无效，若为手牌中点数最大的牌则额外摸牌",

  ["$hongya1"] = "",
  ["$hongya2"] = "",
}

hongya:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hongya.name) and
      data.from ~= player and not player:isKongcheng() and
      player:usedSkillTimes(hongya.name, Player.HistoryTurn) < 2 and
      data.card.number < 13 and data.card.number > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = hongya.name,
      pattern = ".|"..(data.card.number + 1).."~13",
      prompt = "#hongya-ask:::"..data.card.number..":"..data.card:toLogString(),
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards or {}
    local yes = table.every(player:getCardIds("h"), function (id)
      return Fk:getCardById(card[1]).number >= Fk:getCardById(id).number
    end)
    room:recastCard(card, player, hongya.name)
    data.nullified = true
    if data.card.sub_type == Card.SubtypeDelayedTrick then
      data:cancelTarget(player)
    end
    if yes and not player.dead then
      local suits = { 1, 2, 3, 4 }
      for _, id in ipairs(player:getCardIds("h")) do
        table.removeOne(suits, Fk:getCardById(id).suit)
      end
      if #suits > 0 then
        player:drawCards(#suits, hongya.name)
      end
    end
  end,
})

return hongya
