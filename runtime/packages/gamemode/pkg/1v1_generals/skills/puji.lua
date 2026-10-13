local puji = fk.CreateSkill {
  name = "v11__puji",
}

Fk:loadTranslationTable{
  ["v11__puji"] = "普济",
  [":v11__puji"] = "出牌阶段限一次，若对手有牌，你可以弃置一张牌，然后弃置其一张牌。然后以此法失去♠牌的角色摸一张牌。",

  ["#v11__puji"] = "普济：弃置一张牌，再弃置对手一张牌，失去♠牌的角色摸一张牌",
}

puji:addEffect("active", {
  anim_type = "control",
  prompt = "#v11__puji",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(puji.name, Player.HistoryPhase) == 0 and not player.next:isNude()
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local drawers = {}
    if Fk:getCardById(effect.cards[1]).suit == Card.Spade then
      table.insert(drawers, player)
    end
    room:throwCard(effect.cards, puji.name, player, player)
    local to = player.next
    if not to:isNude() then
      local cid = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = puji.name,
      })
      if Fk:getCardById(cid).suit == Card.Spade then
        table.insert(drawers, to)
      end
      room:throwCard(cid, puji.name, to, player)
    end
    for _, p in ipairs(drawers) do
      if not p.dead then
        p:drawCards(1, puji.name)
      end
    end
  end,
})

return puji
