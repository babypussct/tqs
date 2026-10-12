local muzhen = fk.CreateSkill {
  name = "muzhen",
}

Fk:loadTranslationTable{
  ["muzhen"] = "睦阵",
  [":muzhen"] = "出牌阶段各限一次，你可以：将一张装备牌置于一名其他角色装备区内，然后获得其一张手牌；交给一名装备区内有牌的其他角色两张牌，"..
  "然后获得其装备区内一张牌。",

  ["muzhen1"] = "置入一张装备，获得一张手牌",
  ["muzhen2"] = "交给两张牌，获得一张装备",
  ["#muzhen1"] = "睦阵：将一张装备牌置于一名其他角色装备区，获得其一张手牌",
  ["#muzhen2"] = "睦阵：交给一名角色两张牌，获得其一张装备",

  ["$muzhen1"] = "行阵和睦，方可优劣得所。",
  ["$muzhen2"] = "识时达务，才可上和下睦。",
}

muzhen:addEffect("active", {
  anim_type = "control",
  min_card_num = 1,
  target_num = 1,
  prompt = function(self)
    return "#"..self.interaction.data
  end,
  interaction = function(self, player)
    local choices = {}
    for _, choice in ipairs({"muzhen1", "muzhen2"}) do
      if player:getMark(choice.."-phase") == 0 then
        table.insert(choices, choice)
      end
    end
    return UI.ComboBox {choices = choices}
  end,
  can_use = function(self, player)
    return player:getMark("muzhen1-phase") == 0 or player:getMark("muzhen2-phase") == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data == "muzhen1" then
      return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
    elseif self.interaction.data == "muzhen2" then
      return #selected < 2
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player then
      if self.interaction.data == "muzhen1" then
        return #selected_cards == 1 and to_select:canMoveCardIntoEquip(selected_cards[1], false)
      elseif self.interaction.data == "muzhen2" then
        return #selected_cards == 2 and #to_select:getCardIds("e") > 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(player, self.interaction.data.."-phase", 1)
    if self.interaction.data == "muzhen1" then
      room:moveCardIntoEquip(target, effect.cards[1], muzhen.name, false, player)
      if not (player.dead or target.dead or target:isKongcheng()) then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "h",
          skill_name = muzhen.name,
        })
        room:obtainCard(player, id, false, fk.ReasonPrey, player, muzhen.name)
      end
    elseif self.interaction.data == "muzhen2" then
      room:obtainCard(target, effect.cards, false, fk.ReasonGive, player, muzhen.name)
      if not (player.dead or target.dead or #target:getCardIds("e") == 0) then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "e",
          skill_name = muzhen.name,
        })
        room:obtainCard(player, id, true, fk.ReasonPrey)
      end
    end
  end,
})

return muzhen
