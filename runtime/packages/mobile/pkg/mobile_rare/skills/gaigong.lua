local gaigong = fk.CreateSkill{
  name = "gaigong",
}

Fk:loadTranslationTable{
  ["gaigong"] = "慨公",
  [":gaigong"] = "每回合限一次，当你对其他角色造成伤害后或受到其他角色造成的伤害后，你可以展示你或该角色的至多两张手牌并与"..
  "牌堆底等量张牌交换；若交换的牌至少包含三种花色，你可以使用其中一张牌（无次数限制且不计入次数限制）。",

  ["#gaigong-choose"] = "慨公：你可以展示你或 %dest 至多两张手牌，并牌堆底等量张牌交换",
  ["#gaigong-use"] = "慨公：你可以使用其中一张牌",

  ["$gaigong1"] = "往昔仇怨，今日尽消。",
  ["$gaigong2"] = "同为国家，岂存私念？",
  ["$gaigong3"] = "明公军令在此，典自当以大局为重。",
  ["$gaigong4"] = "此国家大事，吾可以私憾而忘公义乎？",
}

---@type TrigSkelSpec<DamageTrigFunc>
local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    if data.from and not data.from:isKongcheng() then
      table.insert(targets, data.from)
    end
    if not data.to:isKongcheng() then
      table.insert(targets, data.to)
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = gaigong.name,
      prompt = "#gaigong-choose::" .. (event == fk.Damage and data.to.id or data.from.id),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards1 = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = 2,
      flag = "h",
      skill_name = gaigong.name,
    })
    room:showCards(cards1, to, player)
    cards1 = table.filter(cards1, function (id)
      return table.contains(to:getCardIds("h"), id)
    end)
    if #cards1 == 0 then return end
    local cards2 = room:getNCards(#cards1, "bottom")
    local all_cards = table.connect(cards1, cards2)
    local suits = {}
    for _, id in ipairs(all_cards) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    room:swapCardsWithPile(to, cards1, cards2, gaigong.name, "Bottom", true, player)
    if #suits > 2 and not player.dead then
      local expand_pile = {}
      for _, id in ipairs(all_cards) do
        if not table.contains(player:getCardIds("h"), id) then
          table.insert(expand_pile, id)
        end
      end
      local use = room:askToUseRealCard(player, {
        pattern = all_cards,
        skill_name = gaigong.name,
        prompt = "#gaigong-use",
        expand_pile = expand_pile,
        cancelable = true,
        skip = true,
      })
      if use then
        use.extra_data = use.extra_data or {}
        use.extra_data.gaigong = player
        room:useCard(use)
      end
    end
  end,
}

gaigong:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gaigong.name) and
      data.to ~= player and
      not (player:isKongcheng() and data.to:isKongcheng()) and
      player:usedSkillTimes(gaigong.name, Player.HistoryTurn) == 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

gaigong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gaigong.name) and
      data.from and data.from ~= player and
      not (player:isKongcheng() and data.from:isKongcheng()) and
      player:usedSkillTimes(gaigong.name, Player.HistoryTurn) == 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return gaigong
