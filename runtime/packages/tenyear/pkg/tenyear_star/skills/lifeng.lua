local lifeng = fk.CreateSkill {
  name = "lifengc",
}

Fk:loadTranslationTable{
  ["lifengc"] = "砺锋",
  [":lifengc"] = "你可以将一张本回合未被使用过的颜色的手牌当不计次数的【杀】或【无懈可击】使用。",

  ["#lifengc"] = "砺锋：将一张牌当不计次数的【杀】或【无懈可击】使用",

  ["$lifengc1"] = "锋出百砺，健卒亦如是。",
  ["$lifengc2"] = "强军者，必校之以三九，练之三伏。",
}

lifeng:addEffect("viewas", {
  pattern = "slash,nullification",
  prompt = "#lifengc",
  interaction = function(self, player)
    local all_names = {"slash", "nullification"}
    local names = player:getViewAsCardNames(lifeng.name, all_names)
    if #names == 0 then return end
    return UI.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
  filter_pattern = function (self, player, card_name)
    local colors = { "red", "black", "nocolor" }
    for _, c in ipairs(player:getTableMark("lifengc-turn")) do
      table.removeOne(colors, c)
    end
    if #colors > 0 then
      return {
        max_num = 1,
        min_num = 1,
        pattern = ".|.|" .. table.concat(colors, ",") .. "|^equip",
      }
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card_name = self.interaction.data
    local card = Fk:cloneCard(card_name)
    card.skillName = lifeng.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return #player:getTableMark("lifengc-turn") < 3
  end,
  enabled_at_response = function(self, player, response)
    return not response and #player:getTableMark("lifengc-turn") < 3
  end,
  enabled_at_nullification = function (self, player, data)
    return #player:getTableMark("lifengc-turn") < 3 and #player:getHandlyIds() > 0
  end,
})

lifeng:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, lifeng.name)
  end,
})

lifeng:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(lifeng.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "lifengc-turn", data.card:getColorString())
  end,
})

lifeng:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      table.insertIfNeed(mark, e.data.card:getColorString())
    end, Player.HistoryTurn)
    if #mark > 0 then
      room:setPlayerMark(player, "lifengc-turn", mark)
    end
  end
end)

return lifeng
