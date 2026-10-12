local lixian = fk.CreateSkill{
  name = "lixian",
}

Fk:loadTranslationTable{
  ["lixian"] = "理贤",
  [":lixian"] = "当你受到伤害后，你可将一张牌当【无中生有】使用。当你以此法使用过三种不同牌名的锦囊牌后，此技能于你的结束阶段也可发动。",

  ["#lixian"] = "理贤：选择一张牌和要转化的牌",
  ["@$lixian"] = "理贤",

  ["$lixian1"] = "柴米油盐也是家国大事，马虎不得。",
  ["$lixian2"] = "军师大人，妾身这步棋走的如何？",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local names = player:getMark("@$lixian")
    if type(names) ~= "table" then
      names = {"ex_nihilo"}
    end
    local use = player.room:askToUseVirtualCard(player, {
      skill_name = lixian.name,
      name = names,
      card_filter = {
        n = 1,
        pattern = ".",
      },
      prompt = "#lixian",
      cancelable = true,
      skip = true,
    })
    if use then
      event:setCostData(self, { tos = use.tos, use = use, anim_type = (use.card.name == "ex_nihilo") and "drawcard" or "control" })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).use
    room:addTableMarkIfNeed(player, "lixian", use.card.trueName)
    room:useCard(use)
  end,
}

lixian:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(lixian.name) and (#player:getHandlyIds() > 0 or #player:getCardIds("e") > 0)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

lixian:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(lixian.name) then
      if player.phase == Player.Start then
        return #player:getTableMark("@$lixian") > 3 and (#player:getHandlyIds() > 0 or #player:getCardIds("e") > 0)
      elseif player.phase == Player.Finish then
        return #player:getTableMark("lixian") > 2 and (#player:getHandlyIds() > 0 or #player:getCardIds("e") > 0)
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

lixian:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@$lixian", 0)
  player.room:setPlayerMark(player, "lixian", 0)
end)

return lixian
