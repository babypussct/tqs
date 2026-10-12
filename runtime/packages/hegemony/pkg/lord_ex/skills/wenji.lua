local wenji = fk.CreateSkill {
  name = "ld__wenji",
}

Fk:loadTranslationTable {
  ["ld__wenji"] = "问计",
  [":ld__wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，然后若其势力与你相同或未确定势力，"..
  "你于此回合内使用此牌无距离与次数限制且不能被响应，否则你交给其另一张牌。",

  ["#ld__wenji-choose"] = "问计：令一名其他角色交给你一张牌，根据其势力是否与你相同执行效果",
  ["#ld__wenji-give"] = "问计：请交给 %dest 一张牌",

  ["$ld__wenji1"] = "言出子口，入于吾耳，可以言未？",
  ["$ld__wenji2"] = "还望先生救我！",
}

local H = require "packages.hegemony.util"

wenji:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wenji.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ld__wenji-choose",
      skill_name = wenji.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { to = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to[1]
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      prompt = "#ld__wenji-give::" .. player.id,
      skill_name = wenji.name,
      cancelable = false,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, wenji.name, nil, false, to)
    if H.compareKingdomWith(player, to, true) then
      if to.dead then return end
      local cards = player:getCardIds("he")
      table.removeOne(cards, card[1])
      if #cards > 0 then
        card = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = wenji.name,
          pattern = tostring(Exppattern{ id = cards }),
          prompt = "#ld__wenji-give::" .. to.id,
          cancelable = false,
        })
        room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, wenji.name, nil, false, player)
      end
    else
      room:addTableMarkIfNeed(player, "ld__wenji-turn", card[1])
    end
  end,
})

wenji:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.hasIntersection(Card:getIdList(card), player:getTableMark("ld__wenji-turn"))
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and table.hasIntersection(Card:getIdList(card), player:getTableMark("ld__wenji-turn"))
  end,
})

wenji:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      table.hasIntersection(Card:getIdList(data.card), player:getTableMark("ld__wenji-turn"))
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return wenji
