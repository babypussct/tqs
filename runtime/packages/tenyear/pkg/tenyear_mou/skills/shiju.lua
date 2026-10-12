local shiju = fk.CreateSkill {
  name = "shiju",
  attached_skill_name = "shiju&",
}

Fk:loadTranslationTable{
  ["shiju"] = "势举",
  [":shiju"] = "每名角色的出牌阶段限一次，其可以交给你一张牌，你可以使用此牌，然后其本回合攻击范围+X（X为你装备区内牌的数量），"..
  "若此牌是装备牌或此牌造成了伤害，你与其各摸两张牌。",

  ["#shiju_self"] = "势举：选择你的一张牌，你可以使用之并获得收益",
  ["#shiju-use"] = "势举：你可以使用此牌，令 %dest 增加攻击范围",
  ["@shiju-turn"] = "势举 范围+",

  ["$shiju1"] = "借力为己用，可攀青云直上。",
  ["$shiju2"] = "应势而动，事半而功倍。",
}

shiju:addEffect("active", {
  anim_type = "support",
  prompt = "#shiju_self",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(shiju.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local id = effect.cards[1]
    if table.contains(player:getCardIds("e"), id) then
      room:moveCardTo(effect.cards, Player.Hand, player, fk.ReasonPrey, shiju.name, nil, false, player)
    end
    if player.dead or not table.contains(player:getCardIds("h"), id) then return end
    local use = room:askToUseRealCard(player, {
      pattern = { id },
      skill_name = shiju.name,
      prompt = "#shiju-use::"..player.id,
      cancelable = true,
    })
    if use then
      if not player.dead then
        room:addPlayerMark(player, "@shiju-turn", #player:getCardIds("e"))
        if use.card.type == Card.TypeEquip or use.damageDealt then
          player:drawCards(2, shiju.name)
          if not player.dead then
            player:drawCards(2, shiju.name)
          end
        end
      end
    end
  end,
})

shiju:addEffect("atkrange", {
  correct_func = function (self, from, to)
    return from:getMark("@shiju-turn")
  end,
})

return shiju
