local skill = fk.CreateSkill {
  name = "diversion_skill",
}

Fk:loadTranslationTable{
  ["#diversion-give"] = "声东击西：交给 %dest 一张手牌，并选择其要将两张牌交给的目标",
  ["#diversion-give2"] = "声东击西：交给 %dest 两张牌",
}

skill:addEffect("cardskill", {
  prompt = "#diversion_skill",
  distance_limit = 1,
  mod_target_filter = function(self, player, to_select, selected, card, extra_data)
    return to_select ~= player and
      ((extra_data and extra_data.bypass_distances) or self:withinDistanceLimit(player, false, card, to_select))
  end,
  target_filter = Util.CardTargetFilter,
  target_num = 1,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to.dead or from:isKongcheng() then return end
    local others = room:getOtherPlayers(to, false)
    table.removeOne(others, from)
    if #others == 0 then return end
    local plist, cid = room:askToChooseCardsAndPlayers(from, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = others,
      pattern = ".|.|.|hand",
      skill_name = skill.name,
      prompt = "#diversion-give::" .. to.id,
      cancelable = false,
      no_indicate = true,
    })
    local target = plist[1]
    room:doIndicate(to, {target})
    room:moveCardTo(cid, Player.Hand, to, fk.ReasonGive, skill.name, nil, false, from)
    if to.dead or target.dead then return end
    local card = to:getCardIds("he")
    if #card > 2 then
      card = room:askToCards(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = skill.name,
        prompt = "#diversion-give2::" .. target.id,
        cancelable = false,
      })
    end
    room:moveCardTo(card, Player.Hand, target, fk.ReasonGive, skill.name, nil, false, from)
  end,
})

return skill
