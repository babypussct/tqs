
local zhongyong = fk.CreateSkill {
  name = "ol__zhongyong",
}

Fk:loadTranslationTable{
  ["ol__zhongyong"] = "忠勇",
  [":ol__zhongyong"] = "当你使用【杀】结算结束后，你可以将此【杀】或目标角色响应的【闪】交给另一名其他角色，"..
  "若此牌为红色，你可以对你攻击范围内一名角色使用一张【杀】。",

  ["#ol__zhongyong-choose"] = "忠勇：将【杀】或【闪】交给一名其他角色，若为红色，你可以使用一张【杀】",
  ["#ol__zhongyong-slash"] = "忠勇：你可以使用一张【杀】",

  ["$ol__zhongyong1"] = "亦忠亦勇，承关将军之风！",
  ["$ol__zhongyong2"] = "吾乃关公麾下，还不受降！"
}

zhongyong:addAuxActiveSkill("#ol__zhongyong_active", {
  card_num = 0,
  target_num = 1,
  interaction = function (self, player)
    return UI.OptionBox { options = self.choices, all_options = { "slash", "jink" }, direct_send = true }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not table.contains(self.targets, to_select)
  end,
})

zhongyong:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhongyong.name) and
      data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not table.contains(data.tos, p)
      end) then
      if player.room:getCardArea(data.card) == Card.Processing then
        return true
      end
      for _, card in ipairs(data.cardsResponded) do
        if card.trueName == "jink" and player.room:getCardArea(card) == Card.DiscardPile then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "slash")
    end
    for _, card in ipairs(data.cardsResponded) do
      if card.trueName == "jink" and room:getCardArea(card) == Card.DiscardPile then
        table.insert(choices, "jink")
        break
      end
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#ol__zhongyong_active",
      prompt = "#ol__zhongyong-choose",
      extra_data = {
        choices = choices,
        targets = data.tos,
      }
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = {}
    if event:getCostData(self).choice == "slash" then
      cards = Card:getIdList(data.card)
    else
      for _, card in ipairs(data.cardsResponded) do
        if card.trueName == "jink" and room:getCardArea(card) == Card.DiscardPile then
          table.insertTableIfNeed(cards, Card:getIdList(card))
        end
      end
    end
    local yes = table.find(cards, function (id)
      return Fk:getCardById(id).color == Card.Red
    end)
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, zhongyong.name, nil, true, player)
    if yes and not player.dead then
      local targets = table.filter(room.alive_players, function (p)
        return player:inMyAttackRange(p)
      end)
      if #targets == 0 then return end
      local use = room:askToUseCard(player, {
        skill_name = zhongyong.name,
        pattern = "slash",
        prompt = "#ol__zhongyong-slash",
        cancelable = true,
        extra_data = {
          exclusive_targets = table.map(targets, Util.IdMapper),
          bypass_distances = true,
          bypass_times = true,
        }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
  end,
})

return zhongyong
