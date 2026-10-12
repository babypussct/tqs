local caifeng = fk.CreateSkill{
  name = "caifeng",
}

Fk:loadTranslationTable{
  ["caifeng"] = "采风",
  [":caifeng"] = "出牌阶段每幅地图限一次，你可以弃置任意张牌，然后从牌堆或弃牌堆中随机获得等量张其余花色的牌。",

  ["#caifeng"] = "采风：弃置任意张牌，获得等量张其余花色的牌",

  ["$caifeng1"] = "世皆吾师，当道法自然。",
  ["$caifeng2"] = "言天下之事，形四方之风，吾道不穷。",
}

caifeng:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#caifeng",
  min_card_num = 1,
  target_num = 0,
  can_use = function (self, player)
    return player:getMark("@[maozhu]") ~= 0 and
      not table.contains(player:getTableMark("caifeng-phase"), player:getMark("@[maozhu]").name)
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "caifeng-phase", player:getMark("@[maozhu]").name)
    local suits = { "spade", "heart", "club", "diamond" }
    for _, id in ipairs(effect.cards) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    room:throwCard(effect.cards, caifeng.name, player, player)
    if player.dead then return end
    local cards = {}
    for i = 1, #room.draw_pile do
      if table.contains(suits, Fk:getCardById(room.draw_pile[i]):getSuitString()) then
        table.insert(cards, room.draw_pile[i])
        if #cards == #effect.cards then
          break
        end
      end
    end
    if #cards < #effect.cards then
      for _, id in ipairs(room.discard_pile) do
        if table.contains(suits, Fk:getCardById(id):getSuitString()) then
          table.insert(cards, id)
          if #cards == #effect.cards then
            break
          end
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, caifeng.name, nil, false, player)
    end
  end,
})

return caifeng
