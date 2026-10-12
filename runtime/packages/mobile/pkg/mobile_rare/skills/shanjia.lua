local shanjia = fk.CreateSkill {
  name = "shanjia",
}

Fk:loadTranslationTable{
  ["shanjia"] = "缮甲",
  [":shanjia"] = "出牌阶段限一次，你可以摸三张牌，然后弃置X张牌（X为3-你本局游戏失去过的装备区里的牌数），"..
  "若你未因此弃置：基本牌，你可以视为使用一张不计入次数且无次数限制的【杀】；锦囊牌，你本阶段使用牌无距离限制。",

  ["#shanjia"] = "缮甲：摸三张牌，然后弃置%arg张牌",
  ["@shanjia"] = "缮甲弃牌",
  ["#shanjia-discard"] = "缮甲：你须弃置%arg张牌，若未弃置基本牌或锦囊牌则获得额外效果",
  ["#shanjia-slash"] = "缮甲：你可以视为使用一张【杀】",

  ["$shanjia1"] = "缮甲厉兵，伺机而行。",
  ["$shanjia2"] = "战，当取精锐之兵，而弃驽钝也。",
}

shanjia:addAcquireEffect(function (self, player)
  player.room:setPlayerMark(player, "@shanjia", 3)
end)
shanjia:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@shanjia", 0)
end)

shanjia:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player)
    return "#shanjia:::"..player:getMark("@shanjia")
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function (self, player)
    return player:usedSkillTimes(shanjia.name, Player.HistoryPhase) == 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    player:drawCards(3, shanjia.name)
    if player.dead then return end
    local x = player:getMark("@shanjia")
    local yes1, yes2 = true, true
    if x > 0 then
      --其实这么写会有个有趣的现象，在摸牌时失去缮甲的话会不用弃牌，待验证
      local cards = room:askToDiscard(player, {
        min_num = x,
        max_num = x,
        include_equip = true,
        skill_name = shanjia.name,
        cancelable = false,
        prompt = "#shanjia-discard:::"..x,
        skip = true,
      })
      if #cards > 0 then
        for _, id in ipairs(cards) do
          if Fk:getCardById(id).type == Card.TypeBasic then
            yes1 = false
          elseif Fk:getCardById(id).type == Card.TypeTrick then
            yes2 = false
          end
        end
        room:throwCard(cards, shanjia.name, player, player)
        if player.dead then return end
      end
    end
    if yes2 then
      room:setPlayerMark(player, "shanjia-phase", 1)
    end
    if yes1 then
      room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = shanjia.name,
        prompt = "#shanjia-slash",
        extra_data = {
          bypass_times = true,
          extraUse = true,
        }
      })
    end
  end,
})

shanjia:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(shanjia.name, true) and player:getMark("@shanjia") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local i = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            i = i + 1
          end
        end
      end
    end
    if i > 0 then
      room:removePlayerMark(player, "@shanjia", i)
    end
  end,
})

shanjia:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:getMark("shanjia-phase") > 0 and card
  end,
})

return shanjia
