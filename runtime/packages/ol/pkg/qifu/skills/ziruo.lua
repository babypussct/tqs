local ziruo = fk.CreateSkill{
  name = "ziruo",
  tags = { Skill.Switch, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ziruo"] = "自若",
  [":ziruo"] = "转换技，锁定技，当你使用，阳：最左侧的手牌时，你摸一张牌；阴：最右侧的手牌时，你摸一张牌。你以此法摸牌后本回合不能调整手牌。",

  ["$ziruo1"] = "泰山虽崩于前，我亦风清云淡。",
  ["$ziruo2"] = "诸君勿忧，一切尽在掌握。",
}


ziruo:addLoseEffect(function (self, player, is_death)
  player.room:unbanSortingHandcards(player, "-_ziruo-turn")
end)

ziruo:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ziruo.name) and
      data.extra_data and data.extra_data.ziruoSideCards then
      if player:getSwitchSkillState(ziruo.name) == fk.SwitchYang then
        return table.contains(Card:getIdList(data.card), data.extra_data.ziruoSideCards[1])
      else
        return table.contains(Card:getIdList(data.card), data.extra_data.ziruoSideCards[2])
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, ziruo.name)
    if not player.dead and player:getMark(MarkEnum.SortProhibited .. "-_ziruo-turn") == 0 then
      room:banSortingHandcards(player, "-_ziruo-turn")
    end
  end,
})

ziruo:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(ziruo.name, true) and not player:isKongcheng()
  end,
  on_refresh = function (self, event, target, player, data)
    if player:canSortHandcards() then
      player.room:syncPlayerClientCards(player)
    end
    local handcards = player:getCardIds("h")
    data.extra_data = data.extra_data or {}
    data.extra_data.ziruoSideCards = { handcards[1], handcards[#handcards] }
  end,
})

return ziruo
