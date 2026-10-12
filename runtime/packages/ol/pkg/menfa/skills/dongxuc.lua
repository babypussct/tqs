local dongxuc = fk.CreateSkill{
  name = "dongxuc",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["dongxuc"] = "动虚",
  [":dongxuc"] = "转换技，阳：你可以将一张装备牌置于一名其他角色的装备区（替换原装备）；"..
  "阴：你可以将手牌摸至攻击范围（至多为5）。然后视为使用一张【闪】或令你被抵消的【杀】依然造成伤害。",

  ["#dongxuc-jink-yang"] = "动虚：将一张装备置入其他角色装备区，视为使用一张【闪】",
  ["#dongxuc-jink-yin"] = "动虚：将手牌摸至%arg，视为使用一张【闪】",
  ["#dongxuc-slash-yang"] = "动虚：将一张装备置入其他角色装备区，令此【杀】依然对 %dest 造成伤害",
  ["#dongxuc-slash-yin"] = "动虚：将手牌摸至%arg，令此【杀】依然对 %dest 造成伤害",

  ["$dongxuc1"] = "",
  ["$dongxuc2"] = "",
}

dongxuc:addAuxActiveSkill("dongxuc_active", {
  card_num = 1,
  target_num = 1,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and #selected_cards == 1 and
      to_select:canMoveCardIntoEquip(selected_cards[1], true)
  end,
})

dongxuc:addEffect("viewas", {
  anim_type = "switch",
  pattern = "jink",
  prompt = function(self, player)
    if player:getSwitchSkillState(dongxuc.name, false) == fk.SwitchYang then
      return "#dongxuc-jink-yang"
    else
      return "#dongxuc-jink-yin:::"..math.min(player:getAttackRange(), 5)
    end
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = ".",
  },
  card_filter = function (self, player, to_select, selected)
    if player:getSwitchSkillState(dongxuc.name, false) == fk.SwitchYang then
      return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
    else
      return false
    end
  end,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    if player:getSwitchSkillState(dongxuc.name, false) == fk.SwitchYang then
      return #selected == 0 and #selected_cards == 1 and to_select ~= player and
        to_select:canMoveCardIntoEquip(selected_cards[1], true)
    else
      return false
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if player:getSwitchSkillState(dongxuc.name, false) == fk.SwitchYang then
      return #selected == 1 and #selected_cards == 1 and selected[1]:canMoveCardIntoEquip(selected_cards[1], true)
    else
      return #selected == 0 and #selected_cards == 0
    end
  end,
  on_use = function (self, room, effect, card, params)
    local player = effect.from
    if card then
      player:drawCards(math.min(player:getAttackRange(), 5) - player:getHandcardNum(), dongxuc.name)
      return ViewAsSkill:onUse(room, effect, card, params)
    else
      local target = effect.tos[1]
      room:moveCardIntoEquip(target, effect.cards, dongxuc.name, true, player)
      card = Fk:cloneCard("jink")
      card.skillName = dongxuc.name
      return ViewAsSkill:onUse(room, effect, card, params)
    end
  end,
  view_as = function(self, player, cards)
    if player:getSwitchSkillState(dongxuc.name, false) == fk.SwitchYang then
      return nil
    else
      local card = Fk:cloneCard("jink")
      card.skillName = dongxuc.name
      return card
    end
  end,
  enabled_at_response = function (self, player, response)
    if not response then
      if player:getSwitchSkillState(dongxuc.name, false) == fk.SwitchYang then
        return not player:isNude()
      else
        return player:getHandcardNum() < math.min(player:getAttackRange(), 5)
      end
    end
  end,
})

dongxuc:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(dongxuc.name) and
      data.card.trueName == "slash" then
      if player:getSwitchSkillState(dongxuc.name, false) == fk.SwitchYang then
        return not player:isNude() and #player.room:getOtherPlayers(player, false) > 0
      else
        return player:getHandcardNum() < math.min(player:getAttackRange(), 5)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(dongxuc.name, false) == fk.SwitchYang then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "#dongxuc_active",
        prompt = "#dongxuc-slash-yang::"..data.to.id,
      })
      if success and dat then
        event:setCostData(self, { tos = dat.targets, cards = dat.cards })
        return true
      end
    else
      event:setCostData(self, nil)
      return room:askToSkillInvoke(player, {
        skill_name = dongxuc.name,
        prompt = "#dongxuc-slash-yin::"..data.to.id..":"..math.min(player:getAttackRange(), 5),
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.isCancellOut = false
    local dat = event:getCostData(self)
    if event:getCostData(self) then
      room:moveCardIntoEquip(dat.tos[1], dat.cards, dongxuc.name, true, player)
    else
      player:drawCards(math.min(player:getAttackRange(), 5) - player:getHandcardNum(), dongxuc.name)
    end
  end,
})

return dongxuc
