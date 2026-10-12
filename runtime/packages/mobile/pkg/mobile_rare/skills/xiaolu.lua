local xiaolu = fk.CreateSkill {
  name = "changshi__xiaolu",
}

Fk:loadTranslationTable{
  ["changshi__xiaolu"] = "宵赂",
  [":changshi__xiaolu"] = "出牌阶段限一次，你可以摸两张牌，然后选择一项：1.弃置两张手牌；2.将两张手牌交给一名其他角色。",

  ["#changshi__xiaolu"] = "宵赂：摸两张牌，然后弃置两张手牌或将两张手牌交给一名其他角色",
  ["changshi__xiaolu_give"] = "交出两张手牌",
  ["changshi__xiaolu_discard"] = "弃置两张手牌",
  ["#changshi__xiaolu-give"] = "宵赂：将%arg张手牌交给一名其他角色",

  ["$changshi__xiaolu1"] = "咱家上下打点，自是要费些银子。",
}

xiaolu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#changshi__xiaolu",
  can_use = function(self, player)
    return player:usedSkillTimes(xiaolu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(2, xiaolu.name)
    if player.dead or player:isKongcheng() then return end
    local choices = {"changshi__xiaolu_discard"}
    if #room:getOtherPlayers(player, false) > 0 then
      table.insert(choices, "changshi__xiaolu_give")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xiaolu.name,
    })
    if choice == "changshi__xiaolu_discard" then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = xiaolu.name,
        cancelable = false,
      })
    else
      local n = math.min(2, player:getHandcardNum())
      local tos, ids = room:askToChooseCardsAndPlayers(player, {
        min_num = 1,
        max_num = 1,
        min_card_num = n,
        max_card_num = n,
        targets = room:getOtherPlayers(player, false),
        skill_name = xiaolu.name,
        prompt = "#xiaolu-give:::"..n,
        cancelable = false,
      })
      room:moveCardTo(ids, Card.PlayerHand, tos[1], fk.ReasonGive, xiaolu.name, nil, false, player)
    end
  end,
})

return xiaolu
