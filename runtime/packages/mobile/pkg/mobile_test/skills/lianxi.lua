local lianxi = fk.CreateSkill {
  name = "lianxi",
}

Fk:loadTranslationTable{
  ["lianxi"] = "连袭",
  [":lianxi"] = "【杀】不计入你的手牌上限；当你的【杀】被弃置进入弃牌堆后，你可以视为使用一张不计入次数且无距离次数限制的普通【杀】。",

  ["#lianxi-use"] = "连袭：你可以视为使用一张无距离次数的【杀】",

  ["$lianxi1"] = "尔等孤军深入，真乃自投死路！",
  ["$lianxi2"] = "汉室衰落，乌桓当兴！",
}

lianxi:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lianxi.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.beforeCard.trueName == "slash" and info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = lianxi.name,
      prompt = "#lianxi-use",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

lianxi:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return player:hasSkill(lianxi.name) and card.trueName == "slash"
  end,
})

return lianxi