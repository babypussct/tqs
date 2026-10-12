local yixing = fk.CreateSkill {
  name = "yixing",
  derived_piles = "yixing",
}

Fk:loadTranslationTable{
  ["yixing"] = "易型",
  [":yixing"] = "出牌阶段限一次，你可以将所有“器”置入弃牌堆并摸等量的牌，然后你可以将任意张装备牌置于你的武将牌上，称为“器”。"..
  "你拥有“器”的所有效果。",

  ["#yixing"] = "易型：将所有“器”置入弃牌堆并摸等量的牌，然后可以将任意张装备牌置为“器”",
  ["#yixing-put"] = "易型：你可以将任意张装备牌置为“器”",

  ["$yixing1"] = "吾即万用之理！",
  ["$yixing2"] = "万事皆顺，万法皆通！",
}

yixing:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#yixing",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(yixing.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = player:getPile(yixing.name)
    if #cards > 0 then
      for _, id in ipairs(cards) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeEquip and card.equip_skills then
          for _, s in ipairs(card.equip_skills) do
            if not table.find(player:getEquipCards(), function (equip)
              return table.contains(equip:getEquipSkills(), s)
            end) then
              room:handleAddLoseSkills(player, "-"..s.name, nil, false, true)
            end
          end
        end
      end
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, yixing.name, nil, true, player)
      if player.dead then return end
      player:drawCards(#cards, yixing.name)
    end
    if player:isNude() or not player:hasSkill(yixing.name, true) then return end
    cards = room:askToCards(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      pattern = ".|.|.|.|.|equip",
      prompt = "#yixing-put",
      skill_name = yixing.name,
    })
    if #cards > 0 then
      for _, id in ipairs(cards) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeEquip and card.equip_skills then
          for _, s in ipairs(card.equip_skills) do
            if not player:hasSkill(s, true) then
              room:handleAddLoseSkills(player, s.name, nil, false, true)
            end
          end
        end
      end
      player:addToPile(yixing.name, cards, true, yixing.name, player)
    end
  end,
})

yixing:addEffect("atkrange", {
  virtual_weapon_func = function(self, player)
    if #player:getPile(yixing.name) > 0 then
      local n = 0
      for _, id in ipairs(player:getPile(yixing.name)) do
        if Fk:getCardById(id).sub_type == Card.SubtypeWeapon then
          n = math.max(n, Fk:getCardById(id).attack_range)
        end
      end
      return n
    end
  end,
})

yixing:addLoseEffect(function (self, player, is_death)
  if #player:getPile(yixing.name) > 0 then
    local room = player.room
    for _, id in ipairs(player:getPile(yixing.name)) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeEquip and card.equip_skills then
        for _, s in ipairs(card.equip_skills) do
          if not table.find(player:getEquipCards(), function (equip)
            return table.contains(equip:getEquipSkills(), s)
          end) then
            room:handleAddLoseSkills(player, "-"..s.name, nil, false, true)
          end
        end
      end
    end
  end
end)

return yixing
