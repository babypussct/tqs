local shangyi = fk.CreateSkill {
  name = "mobile__shangyi",
}

Fk:loadTranslationTable{
  ["mobile__shangyi"] = "尚义",
  [":mobile__shangyi"] = "出牌阶段限一次，你可以弃置一张牌并令一名有手牌的其他角色，其观看你的手牌，然后你观看其手牌并获得其中一张牌。",

  ["#mobile__shangyi"] = "尚义：弃置一张牌令一名角色观看你的手牌，然后你观看其手牌并获得其中一张牌",

  ["$mobile__shangyi1"] = "国士，当以义为先！",
  ["$mobile__shangyi2"] = "豪侠尚义，何拘俗礼！",
}

shangyi:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile__shangyi",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(shangyi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, shangyi.name, player, player)
    if player.dead or target.dead then return end
    if not player:isKongcheng() then
      room:viewCards(target, { cards = player:getCardIds("h"), skill_name = shangyi.name, prompt = "$ViewCardsFrom:"..player.id })
    end
    if not target:isKongcheng() then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = {
          card_data = {{target.general, target:getCardIds("h")} }
        },
        skill_name = shangyi.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, shangyi.name)
    end
  end,
})

return shangyi
