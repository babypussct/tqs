local daoji = fk.CreateSkill {
  name = "daoji"
}

Fk:loadTranslationTable{
  ["daoji"] = "盗戟",
  [":daoji"] = "出牌阶段限一次，你可以弃置一张非基本牌并选择一名装备区有牌的其他角色，你获得其装备区一张牌并使用之。" ..
  "若你以此法获得的牌为武器牌，你再对其造成1点伤害。",

  ["#daoji"] = "盗戟：弃一张非基本牌并选择一名装备区有牌的角色，获得其一张装备，若为武器则对其造成伤害",
  ["#daoji-use"] = "盗戟：请使用%arg",

  ["$daoji1"] = "八十斤双戟？于我如探囊取物！",
  ["$daoji2"] = "以汝之矛，攻汝之盾！",
}

daoji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#daoji",
  can_use = function(self, player)
    return player:usedSkillTimes(daoji.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic and not player:prohibitDiscard(to_select)
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #to_select:getCardIds("e") > 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, daoji.name, player, player)
    if player.dead or target.dead or #target:getCardIds("e") == 0 then return end
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "e",
      skill_name = daoji.name,
    })
    local card = Fk:getCardById(id)
    room:obtainCard(player, id, false, fk.ReasonPrey, player, daoji.name)
    if player.dead then return end
    if card.type == Card.TypeEquip and table.contains(player:getCardIds("h"), id) then
      if player:canUseTo(card, player) then
        room:useCard{
          from = player,
          tos = {player},
          card = card,
        }
      else
        room:askToUseRealCard(player, {
          pattern = {card.id},
          skill_name = daoji.name,
          prompt = "#daoji-use:::"..card:toLogString(),
          cancelable = false,
        })
      end
      if not target.dead and card.sub_type == Card.SubtypeWeapon then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = daoji.name,
        }
      end
    end
  end,
})

return daoji
