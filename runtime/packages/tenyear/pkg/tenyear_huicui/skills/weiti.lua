local weiti = fk.CreateSkill {
  name = "weiti",
}

Fk:loadTranslationTable{
  ["weiti"] = "伪涕",
  [":weiti"] = "出牌阶段限两次，你可以选择一项令一名角色执行：1.受到1点伤害，然后摸两张与手牌点数均不同的牌；2.回复1点体力，然后弃置两张点数不同的牌。",

  ["#weiti"] = "伪涕：选择一项令一名角色执行",
  ["weiti_damage"] = "受到1点伤害，摸两张与手牌点数均不同的牌",
  ["weiti_recover"] = "回复1点体力，弃置两张点数不同的牌",
  ["#weiti-discard-one"] = "伪涕：请弃置一张牌",
  ["#weiti-discard"] = "伪涕：请弃置两张点数不同的牌",

  ["$weiti1"] = "王当行，勿多言，唯流涕尔。",
  ["$weiti2"] = "植有华藻千斤，不及一泪之重。",
}

weiti:addAuxActiveSkill("weiti_active", {
  card_num = 2,
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    return not player:prohibitDiscard(to_select) and
      not table.find(selected, function (id)
        return Fk:getCardById(id).number == Fk:getCardById(to_select).number
      end)
  end,
})

weiti:addEffect("active", {
  anim_type = "control",
  prompt = "#weiti",
  max_phase_use_time = 2,
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox { choices = { "weiti_damage", "weiti_recover" }},
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function (self, room, effect)
    local target = effect.tos[1]
    if self.interaction.data == "weiti_damage" then
      room:damage{
        from = nil,
        to = target,
        damage = 1,
        skillName = weiti.name,
      }
      if target.dead then return end
      local excluded_nums = {}
      for _, cid in ipairs(target:getCardIds("h")) do
        excluded_nums[Fk:getCardById(cid).number] = true
      end
      local toget = {}
      for i = #room.draw_pile, 1, -1 do
        local cd = Fk:getCardById(room.draw_pile[i])
        if not excluded_nums[cd.number] then
          table.insert(toget, cd.id)
          if #toget == 2 then break end
        end
      end
      if #toget > 0 then
        room:moveCardTo(toget, Card.PlayerHand, target, fk.ReasonJustMove, weiti.name, nil, false, target)
      end
    else
      room:recover{
        who = target,
        num = 1,
        recoverBy = target,
        skillName = weiti.name,
      }
      if target.dead then return end
      local cards = table.filter(target:getCardIds("he"), function (id)
        return not target:prohibitDiscard(id)
      end)
      if #cards == 0 then return end
      if #cards == 1 then
        room:throwCard(cards, weiti.name, target, target)
        return
      end

      local card1Num = Fk:getCardById(cards[1]).number
      if table.every(cards, function(id)
        return Fk:getCardById(id).number == card1Num
      end) then
        room:askToDiscard(target, {
          skill_name = weiti.name,
          min_num = 1,
          max_num = 1,
          include_equip = true,
          prompt = "#weiti-discard-one",
          cancelable = false,
        })
      else
        local toThrow
        local _, dat = room:askToUseActiveSkill(target, {
          skill_name = "weiti_active",
          prompt = "#weiti-discard",
          cancelable = false,
        })
        if dat then
          toThrow = dat.cards
        else
          toThrow = {}
          local id1 = room:tableRandomPick(cards)
          table.insert(toThrow, id1)
          local id2 = table.find(cards, function (id)
            return Fk:getCardById(id).number ~= Fk:getCardById(id1).number
          end)
          table.insert(toThrow, id2)
        end
        room:throwCard(toThrow, weiti.name, target, target)
      end
    end
  end,
})

return weiti
