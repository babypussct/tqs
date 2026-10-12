local anxu = fk.CreateSkill {
  name = "ol_ex__anxu",
}

Fk:loadTranslationTable{
  ["ol_ex__anxu"] = "安恤",
  [":ol_ex__anxu"] = "出牌阶段限一次，你可以获得两名角色各一张牌，然后你展示一张手牌并交给其中手牌较少的角色，若不为♠，你摸一张牌。",

  ["#ol_ex__anxu"] = "安恤：获得两名角色各一张牌，然后交给其中手牌较少的角色一张牌",
  ["#ol_ex__anxu-give"] = "安恤：请展示一张牌，若不为♠你摸一张牌",

  ["$ol_ex__anxu1"] = "施仁以济恤，清心而安神。",
  ["$ol_ex__anxu2"] = "写心之舒悦，展容之解颐。",
}

anxu:addEffect("active", {
  anim_type = "control",
  prompt = "#ol_ex__anxu",
  card_num = 0,
  target_num = 2,
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected < 2 then
      if to_select == player then
        return #player:getCardIds("e") > 0
      else
        return not to_select:isNude()
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    --room:sortByAction(effect.tos)
    for _, p in ipairs(effect.tos) do
      local flag = (p == player and "e" or "he")
      if #p:getCardIds(flag) > 0 then
        local card = room:askToChooseCard(player, {
          target = p,
          flag = flag,
          skill_name = anxu.name,
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, anxu.name, nil, false, player)
        if player.dead then return end
      end
    end
    if player.dead or player:isNude() then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = anxu.name,
      prompt = "#ol_ex__anxu-give",
      cancelable = false,
    })
    local yes = Fk:getCardById(card[1]).suit ~= Card.Spade
    player:showCards(card)
    if table.contains(player:getCardIds("h"), card[1]) and
      not (player.dead or effect.tos[1].dead or effect.tos[2].dead) then
      local to = player
      local diff = effect.tos[1]:getHandcardNum() - effect.tos[2]:getHandcardNum()
      if diff > 0 then
        to = effect.tos[2]
      elseif diff < 0 then
        to = effect.tos[1]
      end
      if to ~= player then
        room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, anxu.name, nil, true, player)
      end
    end
    if yes and not player.dead then
      player:drawCards(1, anxu.name)
    end
  end,
})

return anxu
