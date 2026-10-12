local osDaoji = fk.CreateSkill {
  name = "os__daoji"
}

Fk:loadTranslationTable{
  ["os__daoji"] = "盗戟",
  [":os__daoji"] = "出牌阶段限一次，你可弃置一张非基本牌并选择一名攻击范围内的其他角色，你获得其一张牌。" ..
  "若你以此法获得的牌为：基本牌，你摸一张牌；装备牌，则你使用此牌，对其造成1点伤害。",

  ["#os__daoji"] = "盗戟：弃置一张非基本牌并选择一名攻击范围内的角色，获得其一张牌，根据此牌类别执行效果",

  ["$os__daoji1"] = "八十斤双戟？于我如探囊取物！",
  ["$os__daoji2"] = "以汝之矛，攻汝之盾！",
}

osDaoji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__daoji",
  can_use = function(self, player)
    return player:usedSkillTimes(osDaoji.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic and not player:prohibitDiscard(to_select)
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:inMyAttackRange(to_select) and not to_select:isNude()
  end,
  on_use = function(self, room, use)
    ---@type string
    local skillName = osDaoji.name
    local player = use.from
    local target = use.tos[1]
    room:throwCard(use.cards, skillName, player, player)
    if player.dead or target.dead then return end
    local id = room:askToChooseCard(
      player,
      {
        target = target,
        flag = "he",
        skill_name = skillName,
      }
    )
    room:obtainCard(player, id, false, fk.ReasonPrey, player, osDaoji.name)
    if player.dead then return end

    local card = Fk:getCardById(id)
    if card.type == Card.TypeBasic then
      player:drawCards(1, skillName)
    elseif card.type == Card.TypeEquip and table.contains(player:getCardIds("h"), id) and player:canUseTo(card, player) then
      room:useCard{
        from = player,
        tos = { player },
        card = card,
      }
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = skillName,
        }
      end
    end
  end,
})

return osDaoji
