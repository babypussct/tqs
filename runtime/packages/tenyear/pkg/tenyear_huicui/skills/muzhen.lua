
local muzhen = fk.CreateSkill{
  name = "ty__muzhen",
}

Fk:loadTranslationTable{
  ["ty__muzhen"] = "睦阵",
  [":ty__muzhen"] = "出牌阶段每种类型限一次，你可以将一种类型的X张牌交给一名其他角色（X为本阶段发动此技能次数），然后选择一项：<br>"..
  "1.令其弃置等量其他类型的牌，不足则全弃并展示手牌；<br>2.获得其场上等量的牌；<br>3.令其展示牌堆顶等量的牌，获得其中此类型的牌。",

  ["#ty__muzhen"] = "睦阵：将一种类型%arg张牌交给一名角色，然后选择一项",
  ["ty__muzhen_discard"] = "令其弃置%arg张非%arg2，不足则全弃并展示手牌",
  ["ty__muzhen_prey"] = "获得其场上%arg张牌",
  ["ty__muzhen_show"] = "令其展示牌堆顶%arg张牌，获得其中的%arg2",

  ["$ty__muzhen1"] = "既为袍泽，当全手足之恩。",
  ["$ty__muzhen2"] = "统御兵马，调和众心，诸君当同仇敌忾。",
}

muzhen:addEffect("active", {
  anim_type = "control",
  card_num = function (self, player)
    return player:usedSkillTimes(muzhen.name, Player.HistoryPhase) + 1
  end,
  target_num = 1,
  prompt = function (self, player, selected_cards, selected_targets)
    return "#ty__muzhen:::"..(player:usedSkillTimes(muzhen.name, Player.HistoryPhase) + 1)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:usedSkillTimes(muzhen.name, Player.HistoryPhase) + 1 and
      not table.contains(player:getTableMark("ty__muzhen-phase"), Fk:getCardById(to_select).type) and
      table.every(selected, function (id)
        return Fk:getCardById(id).type == Fk:getCardById(to_select).type
      end)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = #effect.cards
    room:addTableMark(player, "ty__muzhen-phase", Fk:getCardById(effect.cards[1]).type)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, muzhen.name, nil, false, player)
    if player.dead or target.dead then return end
    local all_choices = {
      "ty__muzhen_discard:::"..n..":"..Fk:getCardById(effect.cards[1]):getTypeString(),
      "ty__muzhen_prey:::"..n,
      "ty__muzhen_show:::"..n..":"..Fk:getCardById(effect.cards[1]):getTypeString(),
    }
    local choices = table.simpleClone(all_choices)
    if #target:getCardIds("ej") == 0 then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = muzhen.name,
      all_choices = all_choices,
    })
    if choice:startsWith("ty__muzhen_discard") then
      local cards = room:askToDiscard(target, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = muzhen.name,
        cancelable = false,
        pattern = ".|.|.|.|.|^"..Fk:getCardById(effect.cards[1]):getTypeString(),
      })
      if #cards < n and not target:isKongcheng() and not target.dead then
        target:showCards(target:getCardIds("h"))
      end
    elseif choice:startsWith("ty__muzhen_prey") then
      local cards = target:getCardIds("ej")
      if #cards > n then
        cards = room:askToChooseCards(player, {
          target = target,
          min = n,
          max = n,
          flag = "ej",
          skill_name = muzhen.name,
        })
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, muzhen.name, nil, false, player)
    elseif choice:startsWith("ty__muzhen_show") then
      local cards = room:getNCards(n)
      room:showCards(cards)
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).type == Fk:getCardById(effect.cards[1]).type
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, target, fk.ReasonJustMove, muzhen.name, nil, true, target)
      end
    end
  end,
})

return muzhen
