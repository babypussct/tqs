local shangyi = fk.CreateSkill {
  name = "os__shangyi",
}

Fk:loadTranslationTable{
  ["os__shangyi"] = "尚义",
  [":os__shangyi"] = "出牌阶段限一次，你可以弃置一张牌并令一名有手牌的其他角色观看你的手牌，然后你观看其手牌并选择一项：1.弃置其中一张牌；"..
  "2.与其交换一张手牌。若弃置的为黑色牌或交换的两张均为红色牌，则你摸一张牌。",

  ["#os__shangyi"] = "尚义：弃置一张牌，与一名有手牌的其他角色互相观看手牌",
  ["#os__shangyi_view"] = "尚义：观看 %src 的手牌",
  ["#os__shangyi-ask"] = "尚义：观看 %dest 的手牌，选择一张牌并选择一项",
  ["os__shangyi_discard"] = "弃置此牌",
  ["os__shangyi_exchange"] = "与其交换此牌",
  ["#os__shangyi-exchange"] = "尚义：选择一张手牌，交换 %dest 的%arg",

  ["$os__shangyi1"] = "国士，当以义为先！",
  ["$os__shangyi2"] = "豪侠尚义，何拘俗礼！",
}

shangyi:addEffect("active", {
  anim_type = "control",
  prompt = "#os__shangyi",
  times = function (self, player)
    return 1 - player:usedSkillTimes(shangyi.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(shangyi.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, shangyi.name, player, player)
    if not player:isKongcheng() then
      room:viewCards(target, { cards = player:getCardIds("h"), skill_name = shangyi.name, prompt = "#os__shangyi_view:" .. player.id })
    end
    local choiceList = {"os__shangyi_discard"}
    if not player:isKongcheng() then table.insert(choiceList, "os__shangyi_exchange") end

    local cards, choice = room:askToChooseCardsAndChoice(player, {
      cards = target:getCardIds("h"),
      choices = choiceList,
      skill_name = shangyi.name,
      prompt ="#os__shangyi-ask::" .. target.id
    })
    local card = Fk:getCardById(cards[1])
    if choice == "os__shangyi_discard" then
      room:throwCard(cards, shangyi.name, target, player)
      if card.color == Card.Black and not player.dead then
        player:drawCards(1, shangyi.name)
      end
    else
      local cids = room:askToCards(player, {
        skill_name = shangyi.name,
        min_num = 1,
        max_num = 1,
        prompt = "#os__shangyi-exchange::" .. target.id .. ":" .. card:toLogString(),
        cancelable = false,
      })
      room:swapCards(player, {
        {player, cids},
        {target, cards},
      }, shangyi.name)
      if card.color == Card.Red and Fk:getCardById(cids[1]).color == Card.Red and not player.dead then
        player:drawCards(1, shangyi.name)
      end
    end
  end,
})

return shangyi
