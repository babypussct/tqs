local collateral = fk.CreateSkill {
  name = "heg__yinsha_collateral_skill",
}

Fk:loadTranslationTable {
  ["heg__yinsha_collateral_skill"] = "借刀杀人",
  ["#heg__yinsha_collateral-slash"] = "借刀杀人：你必须对 %dest 使用【杀】，否则点“取消”将所有手牌当【杀】使用",
}

collateral:addEffect("cardskill", {
  prompt = "#collateral_skill",
  mod_target_filter = function(self, player, to_select, selected, card, extra_data)
    if #selected == 0 then
      return to_select ~= player and #to_select:getEquipments(Card.SubtypeWeapon) > 0
    elseif #selected == 1 then
      return selected[1]:inMyAttackRange(to_select)
    end
  end,
  target_filter = function(self, player, to_select, selected, _, card, extra_data)
    if #selected >= 2 then
      return false
    elseif #selected == 0 then
      return Util.CardTargetFilter(self, player, to_select, selected, _, card, extra_data)
    else
      return selected[1]:inMyAttackRange(to_select)
    end
  end,
  target_num = 2,
  on_use = function(self, room, cardUseEvent)
    local tos = table.simpleClone(cardUseEvent.tos)
    cardUseEvent:removeAllTargets()
    for i = 1, #tos, 2 do
      cardUseEvent:addTarget(tos[i], { tos[i + 1] })
    end
  end,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to.dead then return end
    local giveWeapon = function()
      if from.dead then return end
      local weapons = to:getEquipments(Card.SubtypeWeapon)
      if #weapons > 0 then
        room:moveCardTo(weapons, Card.PlayerHand, from, fk.ReasonGive, collateral.name, nil, true, to)
      end
    end
    if #(effect.subTargets or {}) == 0 then
      giveWeapon()
      return
    end

    local prompt = "#heg__yinsha_collateral-slash:" .. effect.from.id .. ":" .. effect.subTargets[1].id
    if #effect.subTargets > 1 then
      prompt = nil
    end
    local extra_data = {
      must_targets = table.map(effect.subTargets, Util.IdMapper),
      bypass_times = true,
    }
    if to:canUse(Fk:cloneCard("slash")) then
      local use = room:askToUseCard(to,
        { skill_name = "slash", pattern = "slash", prompt = prompt, cancelable = true, extra_data = extra_data, event_data =
        effect })
      if use then
        use.extraUse = true
        room:useCard(use)
      else
        if to:isKongcheng() then
          giveWeapon()
        else
          room:useVirtualCard("slash", to:getCardIds("h"), to, effect.subTargets, collateral.name, true)
        end
      end
    else
      giveWeapon()
    end
  end,
})

return collateral
