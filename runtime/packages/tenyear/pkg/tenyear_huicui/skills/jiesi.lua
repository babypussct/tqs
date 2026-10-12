local jiesi = fk.CreateSkill{
  name = "jiesi",
}

Fk:loadTranslationTable{
  ["jiesi"] = "捷思",
  [":jiesi"] = "出牌阶段限一次，你可以获得一张指定牌名字数的牌，若本阶段未以此法获得过该牌名，你可以弃置此牌牌名字数张牌，令此技能视为未发动过。",

  ["#jiesi"] = "捷思：获得一张指定牌名字数的牌",
  ["#jiesi-discard"] = "捷思：是否弃置%arg张牌，令“捷思”视为未发动过？",

  ["$jiesi1"] = "古之懿士，当为我辈行履之师。",
  ["$jiesi2"] = "君子周而不比，群而不党。",
}

jiesi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#jiesi",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    return UI.Spin {
      from = 1,
      to = 5,
    }
  end,
  can_use = function (self, player)
    return player:usedSkillTimes(jiesi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = table.filter(room.draw_pile, function(id)
      return Fk:getCardById(id):getNameLength() == self.interaction.data
    end)

    if #cards == 0 then
      cards = table.filter(room.discard_pile, function(id)
        return Fk:getCardById(id):getNameLength() == self.interaction.data
      end)
    end

    local card
    if #cards > 0 then
      card = room:tableRandomPick(cards)
    else
      card = room:getNCards(1)[1]
    end
    card = Fk:getCardById(card)
    local yes = room:addTableMarkIfNeed(player, "jiesi-phase", card.trueName)
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, jiesi.name, nil, false, player)
    if yes and not player:isNude() and not player.dead then
      local n = card:getNameLength()
      if #room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = jiesi.name,
        cancelable = true,
        prompt = "#jiesi-discard:::"..n,
      }) == n then
        player:setSkillUseHistory(jiesi.name, 0, Player.HistoryPhase)
      end
    end
  end,
})

return jiesi
