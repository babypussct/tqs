local wendao = fk.CreateSkill{
  name = "wendao",
}
Fk:loadTranslationTable{
  ["wendao"] = "问道",
  [":wendao"] = "出牌阶段限一次，你可弃置一张不为【太平要术】的红色牌，你获得弃牌堆里或一名角色的装备区里的【太平要术】。",

  ["$wendao1"] = "诚心求天地之道，救世之法。",
  ["$wendao2"] = "求太平之法以安天下。",
}
wendao:addEffect("active", {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(wendao.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local card = Fk:getCardById(to_select)
      return card.color == Card.Red and card.name ~= "peace_spell" and not player:prohibitDiscard(card)
    end
  end,
  target_filter = Util.FalseFunc,
  target_num = 0,
  card_num = 1,
  on_use = function(self, room, effect)
    local from = effect.from
    room:throwCard(effect.cards, wendao.name, from, from)
    local card = room:getCardsFromPileByRule("peace_spell", 1, "discardPile")
    if #card > 0 then
      room:obtainCard(from, card[1], false, fk.ReasonPrey)
    else
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds("e")) do
          if Fk:getCardById(id).name == "peace_spell" then
            room:obtainCard(from, id, false, fk.ReasonPrey)
            return false
          end
        end
      end
    end
  end,
})

return wendao
