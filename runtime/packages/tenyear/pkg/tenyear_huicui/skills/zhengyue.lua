local zhengyue = fk.CreateSkill {
  name = "zhengyue",
  derived_piles = "@[zhengyue]",
}

Fk:loadTranslationTable{
  ["zhengyue"] = "征越",
  [":zhengyue"] = "回合开始时，若你的武将牌上没有“征越”牌，你可以将牌堆顶至多五张牌以任意顺序置于武将牌上。当你使用牌结算后，"..
  "若与武将牌上第一张“征越”牌点数或花色或牌名相同，移去第一张“征越”牌并摸两张牌；若皆不同，将此牌置于武将牌上并任意调整顺序"..
  "（至多5张“征越”牌），当你一回合内以此法将两张牌置为“征越”牌后，你不能使用手牌直到回合结束。",

  ["@[zhengyue]"] = "征越",
  ["#zhengyue-invoke"] = "征越：将牌堆顶至多五张牌置为“征越”牌",

  ["$zhengyue1"] = "本将军出手，必教尔等蛮夷俯首系颈！",
  ["$zhengyue2"] = "什么山越宗帅，还不是一群土鸡瓦狗！",
}

---@param player Player
---@param findOne? boolean
---@return integer[]
local getZhengyueCards = function(player, findOne)
  local mark = player:getTableMark("zhengyue")
  local pile = player:getPile("@[zhengyue]")
  if #pile == 0 then
    return {}
  end
  if findOne then
    for _, id in ipairs(mark) do
      if table.contains(pile, id) then
        return { id }
      end
    end
    return { pile[1] }
  else
    local cards = table.filter(mark, function (id)
      return table.removeOne(pile, id)
    end)
    table.insertTable(cards, pile)
    return cards
  end
end

Fk:addQmlMark{
  name = "zhengyue",
  how_to_show = function(name, value, p)
    if type(value) ~= "table" then return " " end
    return tostring(#value)
  end,
  qml = function(name, value, p)
    return {
      uri = "LunarLtk.Pages.InfoPopups",
      name = "ViewPile",
      prop = {
        ids = getZhengyueCards(p)
      },
    }
  end,
}

zhengyue:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengyue.name) and #player:getPile("@[zhengyue]") == 0
  end,
  on_cost = function (self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = { "1", "2", "3", "4", "5" },
      skill_name = zhengyue.name,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = tonumber(choice) })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local result = room:askToGuanxing(player, {
      cards = room:getNCards(event:getCostData(self).choice),
      bottom_limit = {0, 0},
      skill_name = zhengyue.name,
      skip = true,
      area_names = {"@[zhengyue]", ""},
    })
    player:addToPile("@[zhengyue]", result.top, false, zhengyue.name, player)
  end,
})

zhengyue:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhengyue.name) and #player:getPile("@[zhengyue]") > 0 then
      local c = Fk:getCardById(getZhengyueCards(player, true)[1])
      if c.number == data.card.number or c:compareSuitWith(data.card) or c.trueName == data.card.trueName then
        return true
      else
        return table.contains({Card.Processing, Card.PlayerJudge, Card.PlayerEquip}, player.room:getCardArea(data.card))
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local c = Fk:getCardById(getZhengyueCards(player, true)[1])
    if c.number == data.card.number or c:compareSuitWith(data.card) or c.trueName == data.card.trueName then
      room:moveCardTo(c, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zhengyue.name, nil, true, player)
      if not player.dead then
        room:setPlayerMark(player, "zhengyue", getZhengyueCards(player))
        player:drawCards(2, zhengyue.name)
      end
    else
      local cards = getZhengyueCards(player)
      local to_put = {}
      for _, id in ipairs(Card:getIdList(data.card)) do
        if #cards >= 5 then break end
        table.insert(to_put, id)
        table.insert(cards, id)
      end
      local result = room:askToGuanxing(player, {
        cards = cards,
        bottom_limit = {0, 0},
        skill_name = zhengyue.name,
        skip = true,
        area_names = {"@[zhengyue]", ""},
      })
      room:setPlayerMark(player, "zhengyue", result.top)

      if #to_put > 0 then
        player:addToPile("@[zhengyue]", to_put, false, zhengyue.name, player)
        room:addPlayerMark(player, "zhengyue-turn", #to_put)
      end

    end
  end,
})

zhengyue:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("zhengyue-turn") > 1 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return zhengyue
