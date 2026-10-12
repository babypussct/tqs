local baoxi = fk.CreateSkill {
  name = "baoxi",
}

Fk:loadTranslationTable{
  ["baoxi"] = "暴袭",
  [":baoxi"] = "每轮各限一次，当一次性至少两张基本牌进入弃牌堆后，你可以减1点体力上限并将一张手牌当【决斗】使用；" ..
  "当一次性至少两张非基本牌进入弃牌堆后，你可减1点体力上限并将一张手牌当不计入次数且无次数限制的【杀】使用。",

  ["#baoxi-use"] = "暴袭：你可以减1点体力上限，将一张手牌当【%arg】使用",

  ["$baoxi1"] = "哈哈哈哈，我要看到遍地血海。",
  ["$baoxi2"] = "大好的军功，岂能放过。",
}

baoxi:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(baoxi.name) or #player:getHandlyIds(true) == 0 then return end

    local basicMark = player:getMark("baoxiBasic-round")
    local notBasicMark = player:getMark("baoxiNotBasic-round")
    if basicMark ~= 0 and notBasicMark ~= 0 then
      return false
    end

    local basicCount = 0
    local notBasicCount = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if basicMark == 0 and card.type == Card.TypeBasic then
            basicCount = basicCount + 1
          elseif notBasicMark == 0 and card.type ~= Card.TypeBasic then
            notBasicCount = notBasicCount + 1
          end
          if basicCount > 1 and notBasicCount > 1 then
            event:setCostData(self, {extra_data = {
              ["baoxiBasic"] = true,
              ["baoxiNotBasic"] = true,
            }})
            return true
          end
        end
      end
    end
    if basicCount > 1 or notBasicCount > 1 then
      event:setCostData(self, {extra_data = {
        ["baoxiBasic"] = basicCount > 1,
        ["baoxiNotBasic"] = notBasicCount > 1,
      }})
      return true
    end
    return false
  end,
  on_trigger = function(self, event, target, player, data)
    local dat = table.simpleClone(event:getCostData(self).extra_data)
    if dat["baoxiBasic"] and player:hasSkill(baoxi.name) and #player:getHandlyIds(true) > 0 then
      event:setCostData(self, {choice = "baoxiBasic"})
      self:doCost(event, target, player, data)
    end
    if dat["baoxiNotBasic"] and player:hasSkill(baoxi.name) and #player:getHandlyIds(true) > 0 then
      event:setCostData(self, {choice = "baoxiNotBasic"})
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local name = choice == "baoxiBasic" and "duel" or "slash"
    local use = room:askToUseVirtualCard(player, {
      name = name,
      skill_name = baoxi.name,
      prompt = "#baoxi-use:::"..name,
      cancelable = true,
      extra_data = {
        bypass_times = true,
      },
      card_filter = {
        n = 1,
        cards = player:getHandlyIds(),
      },
      skip = true,
    })
    if use then
      room:setPlayerMark(player, choice.."-round", 1)
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:useCard(event:getCostData(self).extra_data)
  end,
})

return baoxi
